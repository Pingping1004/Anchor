import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Goal.startDate) var allGoals: [Goal]
    
    @StateObject private var viewModel = HomeViewModel()
    
    @State var isShowingCreateGoal = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                List {
                    Group {
                        VStack(alignment: .leading, spacing: 24) {
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Welcome Back")
                                    .font(.title.bold())
                                    .foregroundStyle(.primary)
                                    .minimumScaleFactor(0.8)
                                    .accessibilityAddTraits(.isHeader)
                                
                                Text("Keep chasing your goals")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Today's Schedule")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(.primary)
                                    .accessibilityAddTraits(.isHeader)
                                
                                dailyScheduleSection
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Your Goal")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(.primary)
                                    .accessibilityAddTraits(.isHeader)
                                    .padding(.bottom)
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    
                    if allGoals.isEmpty {
                        emptyGoalState
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(allGoals) { goal in
                            GoalListView(goal: goal)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            goal.deleteGoal(context: context)
                                        }
                                        
                                        HapticSoundManager.shared.play(.sent)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                        }
                    }
                    
                    Color.clear.frame(height: 40)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isShowingCreateGoal = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.body.weight(.bold))
                                .foregroundStyle(LinearGradient.primaryGradient)
                                .contentShape(Circle())
                        }
                        .accessibilityLabel("Create New Goal")
                    }
                }
                .sheet(isPresented: $isShowingCreateGoal) {
                    NavigationStack {
                        CreateGoal()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            viewModel.updateGoals(allGoals)
        }
        .onChange(of: allGoals) { _, newGoals in
            viewModel.updateGoals(newGoals)
        }
    }
    
    private var emptyGoalState: some View {
        VStack(spacing: 24) {
            ContentUnavailableView("No Goals Yet", systemImage: "target", description: Text("Tap + to start."))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            
            Button(role: .confirm) {
                withAnimation {
                    isShowingCreateGoal = true
                }
            } label: {
                Text("Create Goal +")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundStyle(LinearGradient.primaryGradient)
            }
        }
    }
    
    private var currentFocusDisplayText: String {
        if let focusTask = viewModel.currentFocusTask,
           let goal = focusTask.goal {
            return "\(focusTask.title) for \(goal.title)"
        }
        
        return ""
    }
    
    private var dailyScheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let focusTask = viewModel.currentFocusTask,
               let _ = focusTask.goal {
                ScheduleRow(
                    icon: "bolt.fill",
                    title: "Current Focus",
                    value: currentFocusDisplayText
                )
            } else {
                ScheduleRow(
                    icon: "bolt.fill",
                    title: "All Clear!",
                    value: "Relax or start new goal"
                )
            }
            
            Divider()
            
            if let goal = viewModel.upcomingDeadlineGoal,
               let goalDeadline = goal.deadline {
                ScheduleRow(
                    icon: "calendar",
                    title: goal.title,
                    value: "Due \(goalDeadline.formatted(date: .abbreviated, time: .omitted))"
                )
            } else {
                ScheduleRow(
                    icon: "calendar",
                    title: "Next Reflection",
                    value: "26 Apr 2025"
                )
            }
        }
        .padding(24)
        .glassEffect(
            .regular.interactive(),
            in: .rect(cornerRadius: 24, style: .continuous)
        )
    }
}

#Preview {
    ContentView()
//        .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .xxxLarge)
        .modelContainer(PreviewContent.container)
}
