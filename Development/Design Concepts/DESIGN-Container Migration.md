# Container Migration System

**⚠️ Design Status: Conceptual - Implementation Details TBD**

*This section outlines the migration concept but requires significant design work to determine the concrete implementation approach.*

**What is Migration?**
Migration is a function that transforms the entire container from version X to version X + 1, preserving user data when automatic key generation changes due to code refactoring.

**Fundamental Migration Abstraction:**

At the highest level, migration is conceptually a pure function:

```swift
/// Core migration function: transform container from version N to version N+1
func migrate(previousContainer: ContainerDefinition) -> ContainerDefinition
```

This function takes a complete description of the previous container version and produces the transformed container for the new version. All migration complexity can be built on this foundation:

```swift
/// Concrete implementation of the migration abstraction
public protocol ContainerMigration {
    /// Transform data from previous container version to current version
    static func migrate(
        from previousContainer: ContainerDefinition, 
        to currentContainer: ContainerDefinition,
        using store: UserDefaults
    ) throws
}

/// Example migration transformation
extension MySettings: ContainerMigration {
    static func migrate(
        from previous: ContainerDefinition,
        to current: ContainerDefinition, 
        using store: UserDefaults
    ) throws {
        // Apply transformation: previousContainer -> currentContainer
        let transformations = detectChanges(from: previous, to: current)
        
        for transformation in transformations {
            switch transformation {
            case .propertyRenamed(from: let oldName, to: let newName):
                // Move data from old key to new key
                migrateKey(from: previous.keyFor(oldName), to: current.keyFor(newName), store: store)
                
            case .propertyRemoved(let name):
                // Clean up obsolete data
                store.removeObject(forKey: previous.keyFor(name))
                
            case .propertyAdded(let name):
                // Register default value for new property
                store.register(defaults: [current.keyFor(name): current.defaultValueFor(name)])
            }
        }
    }
}
```

**Benefits of Function-Based Migration:**
- **Pure Transformation**: Clear input/output relationship
- **Composable**: Can chain multiple version transformations
- **Testable**: Easy to test with known inputs and expected outputs  
- **Deterministic**: Same input always produces same output
- **Reversible**: Could theoretically implement reverse transformations

**When Migration is Needed:**
- **Module name changes**: Refactoring moves container to different module
- **Container type renames**: Class/struct name changes affect key generation
- **Property renames**: Property name changes require data preservation
- **Prefix strategy changes**: App decides to change key prefixing approach
- **Encoding scheme updates**: Future evolution of key composition rules

**Migration Execution Model:**
- **Once per launch**: Migration runs only when app detects older UserDefaults version
- **Automatic detection**: System compares stored version with current container version
- **Version tracking**: Migration stores its completion alongside transformed data
- **Idempotent**: Safe to run multiple times, only executes when needed

**Open Design Questions:**
- How does the macro system detect when keys have changed?
- Where and how are migration rules defined and stored?
- How to ensure migration runs before any UserDefault access?
- How to handle complex scenarios like module splits or merges?
- What happens when migration fails partway through?
- How to test migrations reliably?

**Practical Approach: Incremental Migration Chain**

The most practical migration approach builds on existing development workflow - developers only need to implement migration from the previous version (N-1) to current version (N). All earlier migrations already exist in the codebase from previous development cycles:

```swift
extension MySettings: UserDefaultsContainer {
    static let version = 3
    static let prefix = "MyApp."
    
    // Current version (N = 3)
    @Setting var username: String = "guest"        // Renamed from userName (v1→v2)
    @Setting var theme: String = "light"           // Unchanged since v1
    @Setting var debugMode: Bool = false           // Renamed from isDebugMode (v2→v3)
    @Setting var maxRetries: Int = 5               // Added in v3
    
    // Only implement migration from previous version (v2 → v3)
    // Migrations v1→v2 already exist in codebase from previous development
    static func migrate(from oldVersion: Int, to newVersion: Int) {
        guard oldVersion == 2 && newVersion == 3 else {
            // All other migration combinations already implemented in previous versions
            return
        }
        
        // Simple N-1 to N migration
        UserDefaultsMigrationManager.migrateKey(
            from: "MyApp.MyModule.MySettings.isDebugMode",
            to: "MyApp.MyModule.MySettings.debugMode",
            container: MySettings.self
        )
        
        // New property maxRetries gets its default value automatically
        // No explicit migration needed for added properties
    }
}
```

**Development Workflow for Migration:**

```swift
// Version 1 → 2 (implemented when moving to v2)
extension MySettings: UserDefaultsContainer {
    static let version = 2
    
    static func migrate(from oldVersion: Int, to newVersion: Int) {
        guard oldVersion == 1 && newVersion == 2 else { return }
        
        UserDefaultsMigrationManager.migrateKey(
            from: "MyApp.MyModule.MySettings.userName",
            to: "MyApp.MyModule.MySettings.username", 
            container: MySettings.self
        )
    }
}

// Version 2 → 3 (implemented when moving to v3)
extension MySettings: UserDefaultsContainer {
    static let version = 3
    
    static func migrate(from oldVersion: Int, to newVersion: Int) {
        guard oldVersion == 2 && newVersion == 3 else { return }
        
        UserDefaultsMigrationManager.migrateKey(
            from: "MyApp.MyModule.MySettings.isDebugMode",
            to: "MyApp.MyModule.MySettings.debugMode",
            container: MySettings.self
        )
    }
}
```

**Benefits of Incremental Migration:**
- **Minimal Developer Burden**: Only implement one migration step when making changes
- **Natural Development Flow**: Migration written when changes are fresh in developer's mind
- **Existing Codebase Assets**: Previous migrations already exist, tested, and deployed
- **Smaller Code Size**: No need to maintain historical version definitions
- **Simple Implementation**: Each migration handles only one version step

**Migration Chain Execution:**

The system automatically chains existing migrations for users with older app versions. **The container version is stored as a key-value pair in UserDefaults itself**, allowing the system to detect what version of data currently exists.

**Stable Version Key Strategy:**

Since UserDefaults stores are inherently scoped to an app (or app group), the version key can be much simpler. The recommended approach leverages store-level isolation:

```swift
/// Migration manager handles chaining of existing migrations
public class UserDefaultsMigrationManager {
    /// Generate stable version key that leverages store-level isolation
    private static func versionKey<Container: UserDefaultsContainer>(
        for containerType: Container.Type
    ) -> String {
        // Option 1: Minimal global key (recommended for most cases)
        return "__version"
        
        // Option 2: Include container prefix to reduce conflict risk
        // return "\(Container.prefix)__version"
        
        // Option 3: Container-specific key (if multiple containers need isolation)
        // return "__\(String(describing: containerType))_version"
    }
    
    /// Execute all necessary migrations from stored version to current version
    public static func migrateIfNeeded<Container: UserDefaultsContainer>(
        _ containerType: Container.Type
    ) {
        let versionKey = self.versionKey(for: containerType)
        let currentCodeVersion = containerType.version  // Version in current code
        let storedDataVersion = Container.store.integer(forKey: versionKey)  // Version of existing data
        
        // First time using this container - initialize version
        if storedDataVersion == 0 {
            Container.store.set(currentCodeVersion, forKey: versionKey)
            Container.store.synchronize()
            return
        }
        
        // No migration needed if data is already at current version
        guard storedDataVersion < currentCodeVersion else { return }
        
        // Chain existing migrations step by step from stored data version to current code version
        for version in (storedDataVersion + 1)...currentCodeVersion {
            print("Migrating \(containerType) from v\(version-1) to v\(version)")
            
            // Each version's migration function only handles its specific step
            containerType.migrate(from: version - 1, to: version)
        }
        
        // Update stored version after successful migration chain
        Container.store.set(currentCodeVersion, forKey: versionKey)
        Container.store.synchronize()
    }
    
    /// Get the currently stored data version for a container
    public static func getStoredVersion<Container: UserDefaultsContainer>(
        for containerType: Container.Type
    ) -> Int {
        let versionKey = self.versionKey(for: containerType)
        return Container.store.integer(forKey: versionKey)
    }
    
    /// Handle version key migration if absolutely necessary (rare)
    public static func migrateVersionKey<Container: UserDefaultsContainer>(
        for containerType: Container.Type,
        from oldVersionKey: String,
        to newVersionKey: String
    ) {
        let store = Container.store
        
        // Only migrate if old key exists and new key doesn't
        guard store.object(forKey: oldVersionKey) != nil,
              store.object(forKey: newVersionKey) == nil else { return }
        
        // Copy version from old to new key
        let version = store.integer(forKey: oldVersionKey)
        store.set(version, forKey: newVersionKey)
        store.removeObject(forKey: oldVersionKey)
        
        print("Migrated version key: \(oldVersionKey) → \(newVersionKey)")
    }
}
```

**Real-World Migration Evolution:**

```swift
// Year 1: Original implementation
extension AppSettings: UserDefaultsContainer {
    static let version = 1  // Code version
    @Setting var userName: String = "guest"
    // No migration needed - system stores version=1 in UserDefaults automatically
}

// Year 2: Fixed naming convention  
extension AppSettings: UserDefaultsContainer {
    static let version = 2  // Updated code version
    @Setting var username: String = "guest"  // Renamed from userName
    
    static func migrate(from oldVersion: Int, to newVersion: Int) {
        guard oldVersion == 1 && newVersion == 2 else { return }
        
        // System detects stored version=1, code version=2, triggers this migration
        UserDefaultsMigrationManager.migrateKey(
            from: "MyApp.MyModule.AppSettings.userName",   // Old key from v1
            to: "MyApp.MyModule.AppSettings.username",     // New key for v2
            container: AppSettings.self
        )
        // System automatically updates stored version to 2 after migration
    }
}

// Year 3: Added debugging support
extension AppSettings: UserDefaultsContainer {
    static let version = 3  // Updated code version
    @Setting var username: String = "guest"
    @Setting var debugMode: Bool = false     // New property
    
    static func migrate(from oldVersion: Int, to newVersion: Int) {
        guard oldVersion == 2 && newVersion == 3 else { return }
        
        // System detects stored version=2, code version=3, triggers this migration
        // New properties get default values automatically - no explicit migration needed
        print("Migrated to v3: added debugMode property")
        // System automatically updates stored version to 3 after migration
    }
}
```

**Version Key Design Principles:**

Since UserDefaults stores provide app-level isolation, the version key can be simplified to leverage this natural scoping:

```swift
// RECOMMENDED: Minimal version key leveraging store isolation
"__version" = 3

// ALTERNATIVE: Include prefix to reduce conflict risk within store
"MyApp.__version" = 3

// AVOID: Complex keys that duplicate store-level isolation
"MyApp.MyModule.AppSettings.__version" = 3  // Unnecessary complexity
```

**Store-Based Isolation Benefits:**

1. **App-Level Scoping**: Each app's UserDefaults store is automatically isolated
   ```swift
   // App A's store: UserDefaults.standard
   "__version" = 2
   
   // App B's store: UserDefaults.standard (different app, different store)
   "__version" = 5
   
   // No conflict possible - different stores
   ```

2. **App Group Scoping**: Shared app groups get shared version tracking
   ```swift
   // Shared app group store: UserDefaults(suiteName: "group.myapp")
   "__version" = 3  // Shared across all apps in the group
   ```

3. **User-Scoped Stores**: Multi-user scenarios get per-user version tracking
   ```swift
   // User A's store: UserDefaults(suiteName: "myapp.userA")
   "__version" = 2
   
   // User B's store: UserDefaults(suiteName: "myapp.userB") 
   "__version" = 3
   ```

**Conflict Risk Assessment:**

The main risk with `"__version"` is accidental conflicts within the same store:

```swift
// POTENTIAL CONFLICT: Multiple containers in same store
extension SettingsContainer: UserDefaultsContainer {
    static let version = 2
    // Uses: "__version" = 2
}

extension CacheContainer: UserDefaultsContainer {
    static let version = 5
    // Uses: "__version" = 5  // Overwrites SettingsContainer version!
}
```

**Third-Party Library Conflicts:**

Well-designed third-party libraries should use their own prefixes and avoid generic keys:

```swift
// GOOD: Well-designed third-party library
"MyLibrary.version" = 1
"MyLibrary.config" = "value"

// BAD: Poorly designed third-party library (library design flaw)
"__version" = 3        // Conflicts with our version key!
"config" = "value"     // Generic unprefixed keys
```

**Reality Check:** Libraries that store unprefixed keys like `"__version"` in shared UserDefaults stores are demonstrating poor library design. This violates established iOS/macOS development conventions where libraries should:

1. **Use Library-Specific Prefixes**: `"LibraryName."`
2. **Avoid Generic Keys**: Never use keys like `"version"`, `"config"`, `"settings"`
3. **Respect Shared Namespaces**: UserDefaults.standard is a shared resource

**Risk Mitigation vs. Design Quality:**

Instead of overengineering our version key to accommodate poorly designed libraries, we can:

1. **Document the Convention**: Make it clear that `"__version"` is reserved
2. **Provide Escape Hatches**: Allow prefix-based version keys when needed
3. **Follow Best Practices**: Lead by example with good library design

**Conflict Mitigation Strategies:**

1. **Accept Minimal Risk** (recommended approach):
   ```swift
   // Use "__version" and rely on good library design practices
   // Risk: Low for well-designed applications and libraries
   // Benefit: Maximum simplicity and clarity
   ```

2. **Include Prefix** (if sharing UserDefaults with questionable libraries):
   ```swift
   // Use "prefix__version" to reduce conflicts with poorly designed libraries
   "MyApp.__version" = 2     // SettingsContainer  
   "MyCache.__version" = 5   // CacheContainer (different prefix)
   ```

3. **Container-Specific Keys** (highest isolation):
   ```swift
   // Use container type in version key for guaranteed uniqueness
   "__SettingsContainer_version" = 2
   "__CacheContainer_version" = 5
   ```

**Recommended Strategy:**

Use `"__version"` as the default approach. This provides:

- **Maximum Simplicity**: Clear, recognizable infrastructure key
- **Natural Isolation**: Leverages UserDefaults store-level scoping
- **Industry Convention**: Follows established patterns for system keys

Only consider alternatives if you have specific constraints:

- **Multiple Containers**: Need to isolate different container versions in the same store
- **Third-Party Library Conflicts**: Working with poorly designed libraries that violate naming conventions
- **Regulatory Requirements**: Environments where key conflicts are absolutely unacceptable

**Library Design Guidelines:**

If you're designing a library that uses UserDefaults:

```swift
// DO: Use library-specific prefixes
"MyAwesomeLibrary.version" = 1
"MyAwesomeLibrary.config.apiEndpoint" = "https://api.example.com"

// DON'T: Use generic unprefixed keys
"version" = 1           // ❌ Conflicts with app's version key
"config" = "value"      // ❌ Too generic
"__version" = 1         // ❌ Conflicts with our convention
```

**When Version Key Changes Are Unavoidable:**

1. **Prefix Strategy Change**: App decides to change its prefix strategy
   ```swift
   // Version 1-2: "com.company.MyApp.__version"
   // Version 3+:  "MyApp.__version" 
   // Requires version key migration in v3
   ```

2. **Container Split/Merge**: Container architecture changes
   ```swift
   // Version 1-2: "MyApp.__version" (single container)
   // Version 3+:  "MyApp.Settings.__version" + "MyApp.Cache.__version" (split containers)
   // Requires careful migration strategy
   ```

**How Version Storage Works:**

```swift
// UserDefaults contains these key-value pairs after each version:

// After first launch with version 1:
"__version" = 1
"MyApp.MyModule.AppSettings.userName" = "guest"

// After migration to version 2:
"__version" = 2              // Updated by migration system
"MyApp.MyModule.AppSettings.username" = "guest"  // Migrated data
// "MyApp.MyModule.AppSettings.userName" removed during migration

// After migration to version 3:  
"__version" = 3              // Updated by migration system
"MyApp.MyModule.AppSettings.username" = "guest"
"MyApp.MyModule.AppSettings.debugMode" = false   // New property with default
```

**Store Isolation Examples:**

```swift
// Single app with UserDefaults.standard
MyApp: UserDefaults.standard
  "__version" = 3
  "MyApp.username" = "john"
  "MyApp.theme" = "dark"

// Different app - completely separate store
OtherApp: UserDefaults.standard (different bundle)
  "__version" = 1              // No conflict with MyApp
  "OtherApp.setting" = "value"

// Shared app group - shared version tracking
AppGroup: UserDefaults(suiteName: "group.mycompany.shared")
  "__version" = 2              // Shared across group members
  "SharedData.syncEnabled" = true

// Multi-user scenario - per-user version tracking  
UserA: UserDefaults(suiteName: "myapp.user123")
  "__version" = 3
  "MyApp.username" = "alice"

UserB: UserDefaults(suiteName: "myapp.user456") 
  "__version" = 2              // User B on older version, needs migration
  "MyApp.username" = "bob"
```

**Version Key Migration Example:**

```swift
extension AppSettings: UserDefaultsContainer {
    static let version = 3
    static let prefix = "MyApp."  // Changed from "com.company.MyApp." in v3
    
    static func migrate(from oldVersion: Int, to newVersion: Int) {
        // Handle version key migration when prefix changes
        if oldVersion == 2 && newVersion == 3 {
            // Migrate version key due to prefix change
            UserDefaultsMigrationManager.migrateVersionKey(
                for: AppSettings.self,
                from: "com.company.MyApp.__version",
                to: "MyApp.__version"
            )
            
            // Then migrate data keys as usual
            UserDefaultsMigrationManager.migratePrefix(
                from: "com.company.MyApp.",
                to: "MyApp.",
                container: AppSettings.self
            )
        }
    }
}
```

**Migration Chain Benefits:**
- **Users on v1** → System runs: v1→v2 migration, then v2→v3 migration
- **Users on v2** → System runs: v2→v3 migration only  
- **Users on v3** → No migration needed

**Practical Implementation Advantages:**
- **Distributed Development**: Each version update adds one migration step
- **Version Control History**: Migration code evolves with application code
- **Testing Reality**: Migration tests align with actual user update patterns
- **Maintenance Simplicity**: No need to reconstruct historical container definitions

**Alternative: Macro-Generated Migration Manifests**
```swift
// Macro could generate this automatically
static let migrationManifest = """
{
  "version": 2,
  "previousVersion": 1,
  "changes": [
    {"type": "rename", "from": "userName", "to": "username"},
    {"type": "rename", "from": "isDebugMode", "to": "debugMode"}
  ]
}
"""
```

**Conceptual Container Version Management:**
```swift
extension MySettings: UserDefaultsContainer {
    static let version = 2  // Increment when migration needed
    static let prefix = "MyApp."
    
    @Setting var username: String = "guest"  // Was "userName" in v1
    @Setting var theme: String = "light"
    
    // Migration from v1 to v2 - DESIGN TBD
    static func migrate(from oldVersion: Int, to newVersion: Int) {
        // How this actually works needs more design
        guard oldVersion == 1 && newVersion == 2 else { return }
        
        // Conceptual migration - actual API TBD
        UserDefaultsMigrationManager.migrateKey(
            from: "MyApp.MyModule.MySettings.userName",   // Old key
            to: "MyApp.MyModule.MySettings.username",     // New key  
            container: MySettings.self
        )
    }
}
```

**Design Challenges to Solve:**
1. **Automatic Detection**: How does the system know what the old keys were?
2. **Execution Timing**: When exactly does migration run in the app lifecycle?
3. **Error Handling**: What happens if migration fails or is interrupted?
4. **Testing**: How to create reliable tests for migration scenarios?
5. **Performance**: How to minimize migration overhead for unchanged containers?
6. **Developer Experience**: How to make migration setup as simple as possible?

*This is a critical feature that needs careful design before implementation.*

**Migration Scenarios:**

```swift
// Scenario 1: Module rename
UserDefaultsMigrationManager.migrateModule(
    from: "OldNetworkKit.MySettings.username",
    to: "NewNetworkKit.MySettings.username",
    container: MySettings.self
)

// Scenario 2: Container type rename
UserDefaultsMigrationManager.migrateContainer(
    from: "MyApp.MyModule.OldSettings.username",
    to: "MyApp.MyModule.NewSettings.username", 
    container: NewSettings.self
)

// Scenario 3: Prefix strategy change
UserDefaultsMigrationManager.migratePrefix(
    from: "com.oldcompany.MyApp.",
    to: "MyApp.",
    container: MySettings.self
)

// Scenario 4: Batch property migration
UserDefaultsMigrationManager.migrateBatch([
    ("oldUserName", "username"),
    ("oldThemeName", "theme"),
    ("oldDebugFlag", "isDebugMode")
], container: MySettings.self)
```

**Migration Implementation:**

```swift
/// Container version tracking and migration execution
public class UserDefaultsMigrationManager {
    
    /// Check if container needs migration and execute if required
    public static func migrateIfNeeded<Container: UserDefaultsContainer>(
        _ containerType: Container.Type
    ) {
        let versionKey = "\(Container.prefix)__container_version"
        let currentVersion = containerType.version
        let storedVersion = Container.store.integer(forKey: versionKey)
        
        // Skip if already at current version
        guard storedVersion < currentVersion else { return }
        
        // Execute migration chain
        for version in (storedVersion + 1)...currentVersion {
            print("Migrating \(containerType) from v\(version-1) to v\(version)")
            containerType.migrate(from: version - 1, to: version)
        }
        
        // Update stored version
        Container.store.set(currentVersion, forKey: versionKey)
        Container.store.synchronize()
    }
    
    /// Migrate single key while preserving data
    public static func migrateKey(
        from oldKey: String,
        to newKey: String,
        container: any UserDefaultsContainer.Type
    ) {
        let store = container.store
        
        // Only migrate if old key exists and new key doesn't
        guard store.object(forKey: oldKey) != nil,
              store.object(forKey: newKey) == nil else { return }
        
        // Copy value from old to new key
        let value = store.object(forKey: oldKey)
        store.set(value, forKey: newKey)
        store.removeObject(forKey: oldKey)
        
        print("Migrated: \(oldKey) → \(newKey)")
    }
}
```

**Automatic Migration Trigger:**

```swift
/// Container protocol with migration support
public protocol UserDefaultsContainer {
    static var version: Int { get }
    static var prefix: String { get }
    static var store: UserDefaults { get }
    
    /// Migration function executed during version transitions
    static func migrate(from oldVersion: Int, to newVersion: Int)
}

extension UserDefaultsContainer {
    /// Default version for containers without migration
    public static var version: Int { 1 }
    
    /// Default no-op migration
    public static func migrate(from oldVersion: Int, to newVersion: Int) {}
    
    /// Automatically check for migration on first access
    internal static func ensureMigration() {
        UserDefaultsMigrationManager.migrateIfNeeded(Self.self)
    }
}
```

**Migration Benefits:**

- **Data Preservation**: User settings survive code refactoring
- **Transparent Evolution**: Automatic key changes don't break user experience  
- **Safe Refactoring**: Developers can rename properties/modules confidently
- **Version Control**: Clear tracking of container schema evolution
- **Rollback Safety**: Migration preserves both old and new data until confirmed
- **Testing Support**: Isolated migration testing with mock containers

**Best Practices:**

- **Increment version** when any change affects automatic key generation
- **Document migrations** in container comments for team awareness
- **Test migrations** with real user data in staging environments
- **Keep migrations simple** - prefer small, focused transformations
- **Consider migration cost** when planning major refactoring

**Examples:**
```swift
extension MySettings: UserDefaultsContainer {
    @Setting var username: String = "anonymous"
    // Generated key: "MyApp.MySettings.username"

    @Setting(key: "user_name") var username: String = "anonymous"  
    // Explicit key: "MyApp.user_name"
}
```