#!/bin/bash

# NestJS CRUD Application Setup Script with TypeORM, MongoDB, Repository Pattern, and DTOs
# This script creates a complete NestJS application structure

set -e

PROJECT_NAME=${1:-"nest-crud-app"}
ENTITY_NAME=${2:-"User"}
ENTITY_NAME_LOWER=$(echo "$ENTITY_NAME" | tr '[:upper:]' '[:lower:]')

echo "🚀 Creating NestJS CRUD Application: $PROJECT_NAME"
echo "📦 Entity: $ENTITY_NAME"

# Create NestJS project
echo "📦 Installing NestJS CLI..."
npm i -g @nestjs/cli

echo "🏗️  Creating NestJS project..."
nest new $PROJECT_NAME --package-manager npm --skip-git

cd $PROJECT_NAME

# Install dependencies (matching your package.json)
echo "📦 Installing dependencies..."
npm install @nestjs/typeorm typeorm mongodb
npm install class-validator class-transformer
npm install @nestjs/config

# Create module structure
echo "🏗️  Creating module structure..."
nest g module $ENTITY_NAME_LOWER
nest g controller $ENTITY_NAME_LOWER
nest g service $ENTITY_NAME_LOWER

# Create directories
mkdir -p src/$ENTITY_NAME_LOWER/dto
mkdir -p src/$ENTITY_NAME_LOWER/entities
mkdir -p src/$ENTITY_NAME_LOWER/repositories

# Create TypeORM Entity
echo "📄 Creating TypeORM Entity..."
cat > src/$ENTITY_NAME_LOWER/entities/$ENTITY_NAME_LOWER.entity.ts << 'EOF'
import { Entity, ObjectIdColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';
import { ObjectId } from 'mongodb';

@Entity('users')
export class User {
  @ObjectIdColumn()
  _id: ObjectId;

  @Column()
  name: string;

  @Column({ unique: true })
  email: string;

  @Column({ nullable: true })
  age: number;

  @Column({ default: true })
  isActive: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
EOF

# Create DTOs
echo "📄 Creating DTOs..."
cat > src/$ENTITY_NAME_LOWER/dto/create-$ENTITY_NAME_LOWER.dto.ts << 'EOF'
import { IsString, IsEmail, IsNumber, IsOptional, IsBoolean, MinLength } from 'class-validator';

export class CreateUserDto {
  @IsString()
  @MinLength(2)
  name: string;

  @IsEmail()
  email: string;

  @IsNumber()
  @IsOptional()
  age?: number;

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}
EOF

cat > src/$ENTITY_NAME_LOWER/dto/update-$ENTITY_NAME_LOWER.dto.ts << 'EOF'
import { IsString, IsEmail, IsNumber, IsOptional, IsBoolean, MinLength } from 'class-validator';

export class UpdateUserDto {
  @IsString()
  @MinLength(2)
  @IsOptional()
  name?: string;

  @IsEmail()
  @IsOptional()
  email?: string;

  @IsNumber()
  @IsOptional()
  age?: number;

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}
EOF

cat > src/$ENTITY_NAME_LOWER/dto/response-$ENTITY_NAME_LOWER.dto.ts << 'EOF'
import { Exclude, Expose, Transform } from 'class-transformer';

@Exclude()
export class ResponseUserDto {
  @Expose()
  @Transform(({ obj }) => obj._id.toString())
  id: string;

  @Expose()
  name: string;

  @Expose()
  email: string;

  @Expose()
  age: number;

  @Expose()
  isActive: boolean;

  @Expose()
  createdAt: Date;

  @Expose()
  updatedAt: Date;
}
EOF

# Create Repository
echo "📄 Creating Repository..."
cat > src/$ENTITY_NAME_LOWER/repositories/$ENTITY_NAME_LOWER.repository.ts << 'EOF'
import { Injectable } from '@nestjs/common';
import { DataSource, Repository, MongoRepository } from 'typeorm';
import { ObjectId } from 'mongodb';
import { User } from '../entities/user.entity';
import { CreateUserDto } from '../dto/create-user.dto';
import { UpdateUserDto } from '../dto/update-user.dto';

@Injectable()
export class UserRepository extends Repository<User> {
  constructor(private dataSource: DataSource) {
    super(User, dataSource.createEntityManager());
  }

  async createUser(createDto: CreateUserDto): Promise<User> {
    const user = this.create(createDto);
    return await this.save(user);
  }

  async findAllUsers(): Promise<User[]> {
    return await this.find();
  }

  async findUserById(id: string): Promise<User | null> {
    try {
      return await this.findOne({
        where: { _id: new ObjectId(id) } as any,
      });
    } catch (error) {
      return null;
    }
  }

  async findUserByEmail(email: string): Promise<User | null> {
    return await this.findOne({ where: { email } as any });
  }

  async updateUser(id: string, updateDto: UpdateUserDto): Promise<User | null> {
    try {
      await this.update({ _id: new ObjectId(id) } as any, updateDto);
      return await this.findUserById(id);
    } catch (error) {
      return null;
    }
  }

  async deleteUser(id: string): Promise<boolean> {
    try {
      const result = await this.delete({ _id: new ObjectId(id) } as any);
      return result.affected > 0;
    } catch (error) {
      return false;
    }
  }

  async findActiveUsers(): Promise<User[]> {
    return await this.find({ where: { isActive: true } as any });
  }

  async countUsers(): Promise<number> {
    return await this.count();
  }
}
EOF

# Update Service
echo "📄 Updating Service..."
cat > src/$ENTITY_NAME_LOWER/$ENTITY_NAME_LOWER.service.ts << 'EOF'
import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { UserRepository } from './repositories/user.repository';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { ResponseUserDto } from './dto/response-user.dto';
import { plainToInstance } from 'class-transformer';

@Injectable()
export class UserService {
  constructor(private readonly userRepository: UserRepository) {}

  async create(createDto: CreateUserDto): Promise<ResponseUserDto> {
    const existingUser = await this.userRepository.findUserByEmail(createDto.email);
    if (existingUser) {
      throw new ConflictException('User with this email already exists');
    }

    const user = await this.userRepository.createUser(createDto);
    return plainToInstance(ResponseUserDto, user, {
      excludeExtraneousValues: true,
    });
  }

  async findAll(): Promise<ResponseUserDto[]> {
    const users = await this.userRepository.findAllUsers();
    return users.map((user) =>
      plainToInstance(ResponseUserDto, user, {
        excludeExtraneousValues: true,
      }),
    );
  }

  async findOne(id: string): Promise<ResponseUserDto> {
    const user = await this.userRepository.findUserById(id);
    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }
    return plainToInstance(ResponseUserDto, user, {
      excludeExtraneousValues: true,
    });
  }

  async update(id: string, updateDto: UpdateUserDto): Promise<ResponseUserDto> {
    if (updateDto.email) {
      const existingUser = await this.userRepository.findUserByEmail(updateDto.email);
      if (existingUser && existingUser._id.toString() !== id) {
        throw new ConflictException('Email already in use by another user');
      }
    }

    const user = await this.userRepository.updateUser(id, updateDto);
    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }
    return plainToInstance(ResponseUserDto, user, {
      excludeExtraneousValues: true,
    });
  }

  async remove(id: string): Promise<void> {
    const deleted = await this.userRepository.deleteUser(id);
    if (!deleted) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }
  }

  async findActive(): Promise<ResponseUserDto[]> {
    const users = await this.userRepository.findActiveUsers();
    return users.map((user) =>
      plainToInstance(ResponseUserDto, user, {
        excludeExtraneousValues: true,
      }),
    );
  }

  async getStats(): Promise<{ total: number; active: number; inactive: number }> {
    const total = await this.userRepository.countUsers();
    const activeUsers = await this.userRepository.findActiveUsers();
    const active = activeUsers.length;
    return { total, active, inactive: total - active };
  }
}
EOF

# Update Controller
echo "📄 Updating Controller..."
cat > src/$ENTITY_NAME_LOWER/$ENTITY_NAME_LOWER.controller.ts << 'EOF'
import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { UserService } from './user.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { ResponseUserDto } from './dto/response-user.dto';

@Controller('users')
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  create(@Body() createDto: CreateUserDto): Promise<ResponseUserDto> {
    return this.userService.create(createDto);
  }

  @Get()
  findAll(): Promise<ResponseUserDto[]> {
    return this.userService.findAll();
  }

  @Get('active')
  findActive(): Promise<ResponseUserDto[]> {
    return this.userService.findActive();
  }

  @Get('stats')
  getStats(): Promise<{ total: number; active: number; inactive: number }> {
    return this.userService.getStats();
  }

  @Get(':id')
  findOne(@Param('id') id: string): Promise<ResponseUserDto> {
    return this.userService.findOne(id);
  }

  @Patch(':id')
  update(
    @Param('id') id: string,
    @Body() updateDto: UpdateUserDto,
  ): Promise<ResponseUserDto> {
    return this.userService.update(id, updateDto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(@Param('id') id: string): Promise<void> {
    return this.userService.remove(id);
  }
}
EOF

# Update Module
echo "📄 Updating Module..."
cat > src/$ENTITY_NAME_LOWER/$ENTITY_NAME_LOWER.module.ts << 'EOF'
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserController } from './user.controller';
import { UserService } from './user.service';
import { User } from './entities/user.entity';
import { UserRepository } from './repositories/user.repository';

@Module({
  imports: [TypeOrmModule.forFeature([User])],
  controllers: [UserController],
  providers: [UserService, UserRepository],
  exports: [UserService, UserRepository],
})
export class UserModule {}
EOF

# Update App Module
echo "📄 Updating App Module..."
cat > src/app.module.ts << 'EOF'
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { UserModule } from './user/user.module';
import { User } from './user/entities/user.entity';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    TypeOrmModule.forRoot({
      type: 'mongodb',
      url: process.env.MONGODB_URI || 'mongodb://localhost:27017/nest-crud-db',
      useUnifiedTopology: true,
      entities: [User],
      synchronize: true, // Set to false in production
    }),
    UserModule,
  ],
})
export class AppModule {}
EOF

# Update main.ts with validation pipe
echo "📄 Updating main.ts..."
cat > src/main.ts << 'EOF'
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  await app.listen(3000);
  console.log(`Application is running on: http://localhost:3000`);
}
bootstrap();
EOF

# Create .env file
echo "📄 Creating .env file..."
cat > .env << 'EOF'
MONGODB_URI=mongodb://localhost:27017/nest-crud-db
PORT=3000
EOF

# Create MongoDB setup script
echo "📄 Creating MongoDB setup script..."
cat > setup-mongodb.sh << 'EOF'
#!/bin/bash

echo "🗄️  Setting up MongoDB database..."

# Check if mongosh is installed
if ! command -v mongosh &> /dev/null; then
    echo "❌ mongosh is not installed. Please install MongoDB Shell first."
    echo "Visit: https://www.mongodb.com/docs/mongodb-shell/install/"
    exit 1
fi

# Database configuration
DB_NAME="nest-crud-db"
COLLECTION_NAME="users"

echo "📦 Creating database: $DB_NAME"
echo "📦 Creating collection: $COLLECTION_NAME"

# Connect and setup database
mongosh --eval "
  use $DB_NAME;
  
  // Create collection with validation
  db.createCollection('$COLLECTION_NAME', {
    validator: {
      \$jsonSchema: {
        bsonType: 'object',
        required: ['name', 'email'],
        properties: {
          name: {
            bsonType: 'string',
            description: 'must be a string and is required'
          },
          email: {
            bsonType: 'string',
            pattern: '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\$',
            description: 'must be a valid email and is required'
          },
          age: {
            bsonType: ['int', 'double'],
            minimum: 0,
            maximum: 150,
            description: 'must be a number between 0 and 150'
          },
          isActive: {
            bsonType: 'bool',
            description: 'must be a boolean'
          }
        }
      }
    }
  });
  
  // Create unique index on email
  db.$COLLECTION_NAME.createIndex({ email: 1 }, { unique: true });
  
  // Create index on isActive for faster queries
  db.$COLLECTION_NAME.createIndex({ isActive: 1 });
  
  print('✅ Database setup complete!');
  print('📊 Collections:');
  db.getCollectionNames();
  print('📑 Indexes on users collection:');
  db.$COLLECTION_NAME.getIndexes();
"

echo ""
echo "✅ MongoDB setup complete!"
echo "🔗 Connection string: mongodb://localhost:27017/$DB_NAME"
EOF

chmod +x setup-mongodb.sh

# Create MongoDB helper scripts
echo "📄 Creating MongoDB helper scripts..."
cat > mongodb-helpers.sh << 'EOF'
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
EOF

chmod +x mongodb-helpers.sh

# Create README
echo "📄 Creating README..."
cat > README_SETUP.md << 'EOF'
# NestJS CRUD Application with TypeORM & MongoDB

## Features
- ✅ TypeORM with MongoDB (no Mongoose schemas)
- ✅ Repository Pattern
- ✅ DTOs with class-validator
- ✅ Data Serialization with class-transformer
- ✅ Complete CRUD operations
- ✅ Error handling
- ✅ MongoDB Shell (mongosh) integration

## Setup

### 1. Setup MongoDB
Make sure MongoDB is running, then setup the database:
```bash
./setup-mongodb.sh
```

This will:
- Create the database and collection
- Add validation rules
- Create indexes for performance

### 2. Install Dependencies & Run
```bash
npm install
npm run start:dev
```

## MongoDB Helper Commands

We've included helpful mongosh scripts:

```bash
# Connect to MongoDB shell
./mongodb-helpers.sh connect

# Seed sample data
./mongodb-helpers.sh seed

# List all users
./mongodb-helpers.sh list

# Count users (total, active, inactive)
./mongodb-helpers.sh count

# Clear all users
./mongodb-helpers.sh clear

# Drop entire database
./mongodb-helpers.sh drop

# Show collection indexes
./mongodb-helpers.sh indexes
```

## API Endpoints

### Basic CRUD
- `POST /users` - Create a new user
- `GET /users` - Get all users
- `GET /users/:id` - Get user by ID
- `PATCH /users/:id` - Update user
- `DELETE /users/:id` - Delete user

### Additional Endpoints
- `GET /users/active` - Get only active users
- `GET /users/stats` - Get user statistics (total, active, inactive)

## Example Requests with mongosh Verification

```bash
# 1. Create a user via API
curl -X POST http://localhost:3000/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "age": 30
  }'

# 2. Verify in mongosh
./mongodb-helpers.sh list

# 3. Get all users via API
curl http://localhost:3000/users

# 4. Get only active users
curl http://localhost:3000/users/active

# 5. Get statistics
curl http://localhost:3000/users/stats

# 6. Get user by ID
curl http://localhost:3000/users/{id}

# 7. Update user
curl -X PATCH http://localhost:3000/users/{id} \
  -H "Content-Type: application/json" \
  -d '{"name": "Jane Doe"}'

# 8. Delete user
curl -X DELETE http://localhost:3000/users/{id}

# 9. Verify deletion in mongosh
./mongodb-helpers.sh count
```

## Direct MongoDB Queries

You can also query directly using mongosh:

```bash
# Connect to database
mongosh mongodb://localhost:27017/nest-crud-db

# Find all users
db.users.find().pretty()

# Find active users only
db.users.find({ isActive: true }).pretty()

# Find user by email
db.users.findOne({ email: "john@example.com" })

# Update user
db.users.updateOne(
  { email: "john@example.com" },
  { $set: { age: 31 } }
)

# Delete user
db.users.deleteOne({ email: "john@example.com" })

# Count documents
db.users.countDocuments()

# Show indexes
db.users.getIndexes()
```

## Project Structure

```
src/
├── user/
│   ├── dto/
│   │   ├── create-user.dto.ts
│   │   ├── update-user.dto.ts
│   │   └── response-user.dto.ts
│   ├── entities/
│   │   └── user.entity.ts (TypeORM Entity)
│   ├── repositories/
│   │   └── user.repository.ts
│   ├── user.controller.ts
│   ├── user.service.ts
│   └── user.module.ts
├── app.module.ts
└── main.ts
```

## TypeORM Entity vs Mongoose Schema

This project uses TypeORM entities instead of Mongoose schemas:

- **TypeORM Entity**: Uses decorators like `@Entity()`, `@Column()`, `@ObjectIdColumn()`
- **No Mongoose**: Direct MongoDB driver through TypeORM
- **ObjectId**: Uses MongoDB's native ObjectId type
- **Repository Pattern**: Custom repository extending TypeORM's Repository class

## Notes

- TypeORM synchronize is set to `true` for development (auto-creates collections)
- Set `synchronize: false` in production
- Uses MongoDB's native driver through TypeORM
- ObjectId handling for MongoDB _id field
EOF

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "   1. cd $PROJECT_NAME"
echo "   2. Setup MongoDB: ./setup-mongodb.sh"
echo "   3. Install dependencies: npm install"
echo "   4. Run: npm run start:dev"
echo "   5. (Optional) Seed data: ./mongodb-helpers.sh seed"
echo "   6. Test API at http://localhost:3000/users"
echo ""
echo "🛠️  MongoDB Helper Commands:"
echo "   ./mongodb-helpers.sh connect  - Connect to MongoDB shell"
echo "   ./mongodb-helpers.sh seed     - Insert sample data"
echo "   ./mongodb-helpers.sh list     - List all users"
echo "   ./mongodb-helpers.sh count    - Count users"
echo ""
echo "📖 Read README_SETUP.md for more details"
