import SwiftUI
import SwiftData
import AlertToast

struct GoalDetail: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) var sizeClass
    @FocusState private var isFocused: Bool
    
    @Bindable var goal: Goal
    
    @State private var graphRefreshId = 0
    @State private var editMode: EditMode = .inactive
    @State private var isWhyGoalMatterExpanded = false
    @State private var showLockedToast: Bool = false
    
    @State private var viewModel: GoalDetailViewModel
    
    init(goal: Goal) {
        self.goal = goal
        self._viewModel = State(initialValue: GoalDetailViewModel(goal: goal))
    }
    
    private var isEditing: Bool {
        editMode == .active
    }
    
    private var editButtonColor: some ShapeStyle {
        if editMode == .active {
            return AnyShapeStyle(LinearGradient.primaryGradient)
        } else {
            return AnyShapeStyle(Color.primary)
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                        if sizeClass == .regular {
                            // iPad: Two Columns
                            HStack(alignment: .top, spacing: 24) {
                                VStack(alignment: .leading, spacing: 16) {
                                    headerSection
                                    
                                    if !goal.tasks.isEmpty {
                                        VStack(alignment: .leading, spacing: 16) {
                                            Text("Goal Roadmap")
                                                .font(.title3.weight(.semibold))
                                                .foregroundStyle(.primary)
                                                .accessibilityAddTraits(.isHeader)
                                            
                                            GoalTaskTimelineView(tasks: goal.allTasksFlattened)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                
                                VStack(spacing: 24) {
                                    GoalOverviewSection(goal: goal)
                                        .frame(maxWidth: .infinity)
                                    
                                    VStack(alignment: .leading, spacing: 16) {
                                        whyMatterSection()
                                        GoalCategoryTags(goalCategories: goal.category, showAllTags: true)
                                    }
                                }
                            }
                        } else {
                            // iPhone: Single Column
                            headerSection
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Goal Roadmap")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.primary)
                                
                                GoalTaskTimelineView(tasks: goal.allTasksFlattened)
                            }
                            
                            whyMatterSection()
                            GoalOverviewSection(goal: goal)
                        }
                    
                    structureSection
                    GoalRecommendationView(goal: goal)
                    }
                .padding()
                .frame(maxWidth: 1000)
                .frame(maxWidth: .infinity)
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, $editMode)
        .toast(isPresenting: $showLockedToast) {
            AlertToast(
                displayMode: .hud,
                type: .systemImage("lock.fill", .secondary),
                title: "Complete Earlier Deadline First",
                style: .style(
                    backgroundColor: Color(.secondarySystemGroupedBackground),
                    titleColor: .primary,
                    titleFont: .caption,
                )
            )
        }
        .alert("Incomplete Tasks", isPresented: $viewModel.showIncompleteAlert) {
            Button("Complete All", role: .destructive) {
                viewModel.completeGoalAndAllSubtasks(context: context)
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("There are unfinished tasks. How would you like to proceed?")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                StyledEditButton(syncMode: $editMode)
            }
        }
        .environment(\.editMode, $editMode)
        .onChange(of: editMode) { oldMode, newMode in
            withAnimation(.snappy) {
                if newMode == .active {
                    UIAccessibility.post(notification: .announcement, argument: "Editing Active")
                } else {
                    isFocused = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        UIAccessibility.post(notification: .announcement, argument: "Changed Saved")
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(goal.title)
                .lineLimit(4)
                .font(.title).fontWeight(.bold)
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.5)
            
            Text("Keep chasing your goals")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
    
    private func whyMatterSection() -> some View {
        Group {
            if isEditing {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Why This Matters To You?")
                        .font(.title3.bold())
                    
                    TextEditorField(text: $viewModel.goal.whyMatter, externalFocus: $isFocused, label: "Goal Important")
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Why This Matters To You?")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    
                    Text(goal.whyMatter)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(isWhyGoalMatterExpanded ? nil : 2)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.snappy) {
                                isWhyGoalMatterExpanded.toggle()
                            }
                        }
                        .accessibilityHint("Tap to \(isWhyGoalMatterExpanded ? "collapse" : "expand") text.")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction(named: isWhyGoalMatterExpanded ? "Collapse Text" : "Expand Text") {
                            withAnimation { isWhyGoalMatterExpanded.toggle() }
                        }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.smooth, value: isEditing)
    }
    
    private var structureSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Goal Structure")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
            
            GoalStructure(
                goal: goal,
                currentTier: 0,
                onToggleRoot: {
                    viewModel.handleGoalToggle(context: context)
                    graphRefreshId += 1
                },
                onRefresh: { graphRefreshId += 1 },
                onLockToast: {
                    HapticSoundManager.shared.play(.error)
                    showLockedToast = true
                },
                isEditing: isEditing
            )
        }
    }
}

#Preview {
    @Previewable @State var previewGoal = PreviewContent.sampleGoal
    
    NavigationStack {
        GoalDetail(goal: previewGoal)
    }
//    .preferredColorScheme(.dark)
    .environment(\.dynamicTypeSize, .xxxLarge)
    .modelContainer(PreviewContent.container)
}
