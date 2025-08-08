import Foundation
import CoreData

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MacroTracker")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error.localizedDescription)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    private init() {}
    
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Save error: \(error)")
            }
        }
    }
    
    // MARK: - User Management
    func saveUser(_ user: User) {
        do {
            let data = try JSONEncoder().encode(user)
            UserDefaults.standard.set(data, forKey: "currentUser")
        } catch {
            print("Error saving user: \(error)")
        }
    }
    
    func loadUser() -> User? {
        guard let data = UserDefaults.standard.data(forKey: "currentUser") else { return nil }
        do {
            return try JSONDecoder().decode(User.self, from: data)
        } catch {
            print("Error loading user: \(error)")
            return nil
        }
    }
    
    // MARK: - Goal Management
    func saveGoal(_ goal: Goal) {
        do {
            let data = try JSONEncoder().encode(goal)
            UserDefaults.standard.set(data, forKey: "currentGoal")
        } catch {
            print("Error saving goal: \(error)")
        }
    }
    
    func loadGoal() -> Goal? {
        guard let data = UserDefaults.standard.data(forKey: "currentGoal") else { return nil }
        do {
            return try JSONDecoder().decode(Goal.self, from: data)
        } catch {
            print("Error loading goal: \(error)")
            return nil
        }
    }
    
    // MARK: - Food Management
    func saveFood(_ food: Food) {
        do {
            var savedFoods = loadFoods()
            savedFoods.append(food)
            let data = try JSONEncoder().encode(savedFoods)
            UserDefaults.standard.set(data, forKey: "savedFoods")
        } catch {
            print("Error saving food: \(error)")
        }
    }
    
    func loadFoods() -> [Food] {
        guard let data = UserDefaults.standard.data(forKey: "savedFoods") else { return [] }
        do {
            return try JSONDecoder().decode([Food].self, from: data)
        } catch {
            print("Error loading foods: \(error)")
            return []
        }
    }
    
    func getFoodsForDate(_ date: Date) -> [Food] {
        let foods = loadFoods()
        let calendar = Calendar.current
        
        return foods.filter { food in
            calendar.isDate(food.timestamp, inSameDayAs: date)
        }
    }
    
    func deleteFood(withId id: UUID) {
        var foods = loadFoods()
        foods.removeAll { $0.id == id }
        
        do {
            let data = try JSONEncoder().encode(foods)
            UserDefaults.standard.set(data, forKey: "savedFoods")
        } catch {
            print("Error deleting food: \(error)")
        }
    }
}