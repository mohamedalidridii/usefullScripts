#!/bin/bash

DB_NAME="nest-crud-db"

case "$1" in
  connect)
    echo "🔗 Connecting to MongoDB..."
    mongosh mongodb://localhost:27017/$DB_NAME
    ;;
  
  seed)
    echo "🌱 Seeding sample data..."
    mongosh mongodb://localhost:27017/$DB_NAME --eval "
      db.users.insertMany([
        {
          name: 'John Doe',
          email: 'john@example.com',
          age: 30,
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date()
        },
        {
          name: 'Jane Smith',
          email: 'jane@example.com',
          age: 25,
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date()
        },
        {
          name: 'Bob Johnson',
          email: 'bob@example.com',
          age: 35,
          isActive: false,
          createdAt: new Date(),
          updatedAt: new Date()
        }
      ]);
      print('✅ Sample data inserted!');
      print('📊 Total users: ' + db.users.countDocuments());
    "
    ;;
  
  list)
    echo "📋 Listing all users..."
    mongosh mongodb://localhost:27017/$DB_NAME --eval "
      db.users.find().pretty();
    "
    ;;
  
  count)
    echo "🔢 Counting users..."
    mongosh mongodb://localhost:27017/$DB_NAME --eval "
      print('Total users: ' + db.users.countDocuments());
      print('Active users: ' + db.users.countDocuments({ isActive: true }));
      print('Inactive users: ' + db.users.countDocuments({ isActive: false }));
    "
    ;;
  
  clear)
    echo "🗑️  Clearing all users..."
    mongosh mongodb://localhost:27017/$DB_NAME --eval "
      const result = db.users.deleteMany({});
      print('Deleted ' + result.deletedCount + ' users');
    "
    ;;
  
  drop)
    echo "⚠️  Dropping database..."
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
      mongosh mongodb://localhost:27017/$DB_NAME --eval "
        db.dropDatabase();
        print('✅ Database dropped!');
      "
    else
      echo "❌ Operation cancelled"
    fi
    ;;
  
  indexes)
    echo "📑 Showing indexes..."
    mongosh mongodb://localhost:27017/$DB_NAME --eval "
      print('Indexes on users collection:');
      printjson(db.users.getIndexes());
    "
    ;;
  
  *)
    echo "MongoDB Helper Commands:"
    echo "  ./mongodb-helpers.sh connect  - Connect to MongoDB shell"
    echo "  ./mongodb-helpers.sh seed     - Insert sample data"
    echo "  ./mongodb-helpers.sh list     - List all users"
    echo "  ./mongodb-helpers.sh count    - Count users"
    echo "  ./mongodb-helpers.sh clear    - Delete all users"
    echo "  ./mongodb-helpers.sh drop     - Drop entire database"
    echo "  ./mongodb-helpers.sh indexes  - Show collection indexes"
    ;;
esac
