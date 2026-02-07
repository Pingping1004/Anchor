import SwiftUI
import SwiftData
import OSLog

@main
struct MyApp: App {
    let logger = Logger(subsystem: "com.Piyatana.SSC26", category: "PreviewData")
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Goal.self, Task.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    preloadSampleData()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    @MainActor
    private func preloadSampleData() {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<Goal>()
        
        do {
            let count = try context.fetchCount(descriptor)
            
            if  count == 0 {
                logger.notice("Database is empty. Injecting Preview Data...")
                PreviewContent.insertSampleData(into: context)
                try context.save()
                
                logger.info("Inserting data complete: Preview Goal added")
            } else {
                logger.debug("Data already exists. Skipping mock data insertion.")
            }
        } catch {
            logger.error("❌ Error checking/seeding data: \(error.localizedDescription)")
        }
    }
}
