#!/bin/bash

# Add New CRUD Module to Existing NestJS Project
# Usage: ./add-module.sh <EntityName> [field1:type field2:type ...]
# Supported types: string, number, boolean, email, date, url, text, array, enum:value1,value2,value3

set -e

ENTITY_NAME=${1:-"Product"}
ENTITY_NAME_LOWER=$(echo "$ENTITY_NAME" | tr '[:upper:]' '[:lower:]')
shift || true
FIELDS=("$@")

echo "🚀 Adding new CRUD module: $ENTITY_NAME"

# Check if we're in a NestJS project
if [ ! -f "nest-cli.json" ]; then
    echo "❌ Error: Not in a NestJS project directory"
    echo "Please run this script from your project root"
    exit 1
fi

# Create module structure
echo "🏗️  Creating module structure..."
nest g module $ENTITY_NAME_LOWER
nest g controller $ENTITY_NAME_LOWER
nest g service $ENTITY_NAME_LOWER

# Create directories
mkdir -p src/$ENTITY_NAME_LOWER/dto
mkdir -p src/$ENTITY_NAME_LOWER/entities
mkdir -p src/$ENTITY_NAME_LOWER/repositories

# Generate field definitions
ENTITY_FIELDS=""
DTO_CREATE_FIELDS=""
DTO_UPDATE_FIELDS=""
DTO_RESPONSE_FIELDS=""
IMPORTS_CREATE="import { IsString, IsEmail, IsNumber, IsOptional, IsBoolean, IsDate, IsUrl, IsArray, IsEnum, MinLength, Min, Max } from 'class-validator';"
IMPORTS_UPDATE="import { IsString, IsEmail, IsNumber, IsOptional, IsBoolean, IsDate, IsUrl, IsArray, IsEnum, MinLength, Min, Max } from 'class-validator';"
ENUM_DEFINITIONS=""

# Default fields if none provided
if [ ${#FIELDS[@]} -eq 0 ]; then
    FIELDS=("name:string" "description:text" "price:number" "isAvailable:boolean")
fi

for field in "${FIELDS[@]}"; do
    IFS=':' read -r field_name field_type field_options <<< "$field"
    
    case $field_type in
        string)
            ENTITY_FIELDS+="  @Column()\n  $field_name: string;\n\n"
            DTO_CREATE_FIELDS+="  @IsString()\n  @MinLength(2)\n  $field_name: string;\n\n"
            DTO_UPDATE_FIELDS+="  @IsString()\n  @MinLength(2)\n  @IsOptional()\n  $field_name?: string;\n\n"
            DTO_RESPONSE_FIELDS+="  @Expose()\n  $field_name: string;\n\n"
            ;;
        text)
            ENTITY_FIELDS+="  @Column({ type: 'text' })\n  $field_name: string;\n\n"
            DTO_CREATE_FIELDS+="  @IsString()\n  @MinLength(10)\n  $field_name: string;\n\n"
            DTO_UPDATE_FIELDS+="  @IsString()\n  @MinLength(10)\n  @IsOptional()\n  $field_name?: string;\n\n"
            DTO_RESPONSE_FIELDS+="  @Expose()\n  $field_name: string;\n\n"
            ;;
        number)
            ENTITY_FIELDS+="  @Column({ nullable: true })\n  $field_name: number;\n\n"
            DTO_CREATE_FIELDS+="  @IsNumber()\n  @Min(0)\n  @IsOptional()\n  $field_name?: number;\n\n"
            DTO_UPDATE_FIELDS+="  @IsNumber()\n  @Min(0)\n  @IsOptional()\n  $field_name?: number;\n\n"
            DTO_RESPONSE_FIELDS+="  @Expose()\n  $field_name: number;\n\n"
            ;;
        boolean)
            ENTITY_FIELDS+="  @Column({ default: true })\n  $field_name: boolean;\n\n"
            DTO_CREATE_FIELDS+="  @IsBoolean()\n  @IsOptional()\n  $field_name?: boolean;\n\n"
            DTO_UPDATE_FIELDS+="  @IsBoolean()\n  @IsOptional()\n  $field_name?: boolean;\n\n"
            DTO_RESPONSE_FIELDS+="  @Expose()\n  $field_name: boolean;\n\n"
            ;;
        email)
            ENTITY_FIELDS+="  @Column({ unique: true })\n  $field_name: string;\n\n"
            DTO_CREATE_FIELDS+="  @IsEmail()\n  $field_name: string;\n\n"
            DTO_UPDATE_FIELDS+="  @IsEmail()\n  @IsOptional()\n  $field_name?: string;\n\n"
            DTO_RESPONSE_FIELDS+="  @Expose()\n  $field_name: string;\n\n"
            ;;
        date)
            ENTITY_FIELDS+="  @Column({ type: 'date', nullable: true })\n  $field_name: Date;\n\n"
            DTO_CREATE_FIELDS+="  @IsDate()\n  @IsOptional()\n  $field_name?: Date;\n\n"
            DTO_UPDATE_FIELDS+="  @IsDate()\n  @IsOptional()\n  $field_name?: Date;\n\n"
            DTO_RESPONSE_FIELDS+="  @Expose()\n  $field_name: Date;\n\n"
            IMPORTS_CREATE="import { IsString, IsEmail, IsNumber, IsOptional, IsBoolean, IsDate, IsUrl, IsArray, IsEnum, MinLength, Min, Max, Type } from 'class-validator';\nimport { Transform } from 'class-transformer';"
            IMPORTS_UPDATE="import { IsString, IsEmail, IsNumber, IsOptional, IsBoolean, IsDate, IsUrl, IsArray, IsEnum, MinLength, Min, Max, Type } from 'class-validator';\nimport { Transform } from 'class-transformer';"
            DTO_CREATE_FIELDS=$(echo -e "$DTO_CREATE_FIELDS" | sed "s/@IsDate()/@Transform(({ value }) => new Date(value))\n  @IsDate()/")
            DTO_UPDATE_FIELDS=$(echo -e "$DTO_UPDATE_FIELDS" | sed "s/@IsDate()/@Transform(({ value }) => new Date(value))\n  @IsDate()/")
            ;;
        url)
            ENTITY_FIELDS+="  @Column({ nullable: true })\n  $field_name: string;\n\n"
            DTO_CREATE_FIELDS+="  @IsUrl()\n  @IsOptional()\n  $field_name?: string;\n\n"
            DTO_UPDATE_FIELDS+="  @IsUrl()\n  @IsOptional()\n  $field_name?: string;\n\n"
            DTO_RESPONSE_FIELDS+="  @Expose()\n  $field_name: string;\n\n"
            ;;
        array)
            ENTITY_FIELDS+="  @Column({ type: 'array', default: [] })\n  $field_name: string[];\n\n"
            DTO_CREATE_FIELDS+="  @IsArray()\n  @IsString({ each: true })\n  @IsOptional()\n  $field_name?: string[];\n\n"
            DTO_UPDATE_FIELDS+="  @IsArray()\n  @IsString({ each: true })\n  @IsOptional()\n  $field_name?: string[];\n\n"
            DTO_RESPONSE_FIELDS+="  @Expose()\n  $field_name: string[];\n\n"
            ;;
        enum)
            # Parse enum values: status:enum:pending,active,completed
            enum_values=$field_options
            enum_name="${field_name^}Enum"
            
            # Create enum definition
            IFS=',' read -ra VALUES <<< "$enum_values"
            enum_def="export enum $enum_name {\n"
            for val in "${VALUES[@]}"; do
                val_upper=$(echo "$val" | tr '[:lower:]' '[:upper:]')
                enum_def+="  $val_upper = '$val',\n"
            done
            enum_def+="}\n\n"
            ENUM_DEFINITIONS+="$enum_def"
            
            # Create enum values string for column
            enum_array="["
            for val in "${VALUES[@]}"; do
                enum_array+="'$val', "
            done
            enum_array="${enum_array%, }]"
            
            ENTITY_FIELDS+="  @Column({ type: 'enum', enum: $enum_array, default: '${VALUES[0]}' })\n  $field_name: $enum_name;\n\n"
            DTO_CREATE_FIELDS+="  @IsEnum($enum_name)\n  @IsOptional()\n  $field_name?: $enum_name;\n\n"
            DTO_UPDATE_FIELDS+="  @IsEnum($enum_name)\n  @IsOptional()\n  $field_name?: $enum_name;\n\n"
            DTO_RESPONSE_FIELDS+="  @Expose()\n  $field_name: $enum_name;\n\n"
            ;;
    esac
done

# Create TypeORM Entity
echo "📄 Creating TypeORM Entity..."
cat > src/$ENTITY_NAME_LOWER/entities/$ENTITY_NAME_LOWER.entity.ts << EOF
import { Entity, ObjectIdColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';
import { ObjectId } from 'mongodb';

$(echo -e "$ENUM_DEFINITIONS")@Entity('${ENTITY_NAME_LOWER}s')
export class $ENTITY_NAME {
  @ObjectIdColumn()
  _id: ObjectId;

$(echo -e "$ENTITY_FIELDS")  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
EOF

# Create Create DTO
echo "📄 Creating Create DTO..."
cat > src/$ENTITY_NAME_LOWER/dto/create-$ENTITY_NAME_LOWER.dto.ts << EOF
$(echo -e "$IMPORTS_CREATE")

$(echo -e "$ENUM_DEFINITIONS")export class Create${ENTITY_NAME}Dto {
$(echo -e "$DTO_CREATE_FIELDS")}
EOF

# Create Update DTO
echo "📄 Creating Update DTO..."
cat > src/$ENTITY_NAME_LOWER/dto/update-$ENTITY_NAME_LOWER.dto.ts << EOF
$(echo -e "$IMPORTS_UPDATE")

$(echo -e "$ENUM_DEFINITIONS")export class Update${ENTITY_NAME}Dto {
$(echo -e "$DTO_UPDATE_FIELDS")}
EOF

# Create Response DTO
echo "📄 Creating Response DTO..."
cat > src/$ENTITY_NAME_LOWER/dto/response-$ENTITY_NAME_LOWER.dto.ts << EOF
import { Exclude, Expose, Transform } from 'class-transformer';

$(echo -e "$ENUM_DEFINITIONS")@Exclude()
export class Response${ENTITY_NAME}Dto {
  @Expose()
  @Transform(({ obj }) => obj._id.toString())
  id: string;

$(echo -e "$DTO_RESPONSE_FIELDS")  @Expose()
  createdAt: Date;

  @Expose()
  updatedAt: Date;
}
EOF

# Create Repository
echo "📄 Creating Repository..."
cat > src/$ENTITY_NAME_LOWER/repositories/$ENTITY_NAME_LOWER.repository.ts << EOF
import { Injectable } from '@nestjs/common';
import { DataSource, Repository } from 'typeorm';
import { ObjectId } from 'mongodb';
import { $ENTITY_NAME } from '../entities/$ENTITY_NAME_LOWER.entity';
import { Create${ENTITY_NAME}Dto } from '../dto/create-$ENTITY_NAME_LOWER.dto';
import { Update${ENTITY_NAME}Dto } from '../dto/update-$ENTITY_NAME_LOWER.dto';

@Injectable()
export class ${ENTITY_NAME}Repository extends Repository<$ENTITY_NAME> {
  constructor(private dataSource: DataSource) {
    super($ENTITY_NAME, dataSource.createEntityManager());
  }

  async create${ENTITY_NAME}(createDto: Create${ENTITY_NAME}Dto): Promise<$ENTITY_NAME> {
    const entity = this.create(createDto);
    return await this.save(entity);
  }

  async findAll${ENTITY_NAME}s(): Promise<$ENTITY_NAME[]> {
    return await this.find();
  }

  async find${ENTITY_NAME}ById(id: string): Promise<$ENTITY_NAME | null> {
    try {
      return await this.findOne({
        where: { _id: new ObjectId(id) } as any,
      });
    } catch (error) {
      return null;
    }
  }

  async update${ENTITY_NAME}(id: string, updateDto: Update${ENTITY_NAME}Dto): Promise<$ENTITY_NAME | null> {
    try {
      await this.update({ _id: new ObjectId(id) } as any, updateDto);
      return await this.find${ENTITY_NAME}ById(id);
    } catch (error) {
      return null;
    }
  }

  async delete${ENTITY_NAME}(id: string): Promise<boolean> {
    try {
      const result = await this.delete({ _id: new ObjectId(id) } as any);
      return result.affected > 0;
    } catch (error) {
      return false;
    }
  }

  async count${ENTITY_NAME}s(): Promise<number> {
    return await this.count();
  }
}
EOF

# Update Service
echo "📄 Creating Service..."
cat > src/$ENTITY_NAME_LOWER/$ENTITY_NAME_LOWER.service.ts << EOF
import { Injectable, NotFoundException } from '@nestjs/common';
import { ${ENTITY_NAME}Repository } from './repositories/$ENTITY_NAME_LOWER.repository';
import { Create${ENTITY_NAME}Dto } from './dto/create-$ENTITY_NAME_LOWER.dto';
import { Update${ENTITY_NAME}Dto } from './dto/update-$ENTITY_NAME_LOWER.dto';
import { Response${ENTITY_NAME}Dto } from './dto/response-$ENTITY_NAME_LOWER.dto';
import { plainToInstance } from 'class-transformer';

@Injectable()
export class ${ENTITY_NAME}Service {
  constructor(private readonly ${ENTITY_NAME_LOWER}Repository: ${ENTITY_NAME}Repository) {}

  async create(createDto: Create${ENTITY_NAME}Dto): Promise<Response${ENTITY_NAME}Dto> {
    const entity = await this.${ENTITY_NAME_LOWER}Repository.create${ENTITY_NAME}(createDto);
    return plainToInstance(Response${ENTITY_NAME}Dto, entity, {
      excludeExtraneousValues: true,
    });
  }

  async findAll(): Promise<Response${ENTITY_NAME}Dto[]> {
    const entities = await this.${ENTITY_NAME_LOWER}Repository.findAll${ENTITY_NAME}s();
    return entities.map((entity) =>
      plainToInstance(Response${ENTITY_NAME}Dto, entity, {
        excludeExtraneousValues: true,
      }),
    );
  }

  async findOne(id: string): Promise<Response${ENTITY_NAME}Dto> {
    const entity = await this.${ENTITY_NAME_LOWER}Repository.find${ENTITY_NAME}ById(id);
    if (!entity) {
      throw new NotFoundException(\`${ENTITY_NAME} with ID \${id} not found\`);
    }
    return plainToInstance(Response${ENTITY_NAME}Dto, entity, {
      excludeExtraneousValues: true,
    });
  }

  async update(id: string, updateDto: Update${ENTITY_NAME}Dto): Promise<Response${ENTITY_NAME}Dto> {
    const entity = await this.${ENTITY_NAME_LOWER}Repository.update${ENTITY_NAME}(id, updateDto);
    if (!entity) {
      throw new NotFoundException(\`${ENTITY_NAME} with ID \${id} not found\`);
    }
    return plainToInstance(Response${ENTITY_NAME}Dto, entity, {
      excludeExtraneousValues: true,
    });
  }

  async remove(id: string): Promise<void> {
    const deleted = await this.${ENTITY_NAME_LOWER}Repository.delete${ENTITY_NAME}(id);
    if (!deleted) {
      throw new NotFoundException(\`${ENTITY_NAME} with ID \${id} not found\`);
    }
  }

  async getStats(): Promise<{ total: number }> {
    const total = await this.${ENTITY_NAME_LOWER}Repository.count${ENTITY_NAME}s();
    return { total };
  }
}
EOF

# Update Controller
echo "📄 Creating Controller..."
cat > src/$ENTITY_NAME_LOWER/$ENTITY_NAME_LOWER.controller.ts << EOF
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
import { ${ENTITY_NAME}Service } from './$ENTITY_NAME_LOWER.service';
import { Create${ENTITY_NAME}Dto } from './dto/create-$ENTITY_NAME_LOWER.dto';
import { Update${ENTITY_NAME}Dto } from './dto/update-$ENTITY_NAME_LOWER.dto';
import { Response${ENTITY_NAME}Dto } from './dto/response-$ENTITY_NAME_LOWER.dto';

@Controller('${ENTITY_NAME_LOWER}s')
export class ${ENTITY_NAME}Controller {
  constructor(private readonly ${ENTITY_NAME_LOWER}Service: ${ENTITY_NAME}Service) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  create(@Body() createDto: Create${ENTITY_NAME}Dto): Promise<Response${ENTITY_NAME}Dto> {
    return this.${ENTITY_NAME_LOWER}Service.create(createDto);
  }

  @Get()
  findAll(): Promise<Response${ENTITY_NAME}Dto[]> {
    return this.${ENTITY_NAME_LOWER}Service.findAll();
  }

  @Get('stats')
  getStats(): Promise<{ total: number }> {
    return this.${ENTITY_NAME_LOWER}Service.getStats();
  }

  @Get(':id')
  findOne(@Param('id') id: string): Promise<Response${ENTITY_NAME}Dto> {
    return this.${ENTITY_NAME_LOWER}Service.findOne(id);
  }

  @Patch(':id')
  update(
    @Param('id') id: string,
    @Body() updateDto: Update${ENTITY_NAME}Dto,
  ): Promise<Response${ENTITY_NAME}Dto> {
    return this.${ENTITY_NAME_LOWER}Service.update(id, updateDto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(@Param('id') id: string): Promise<void> {
    return this.${ENTITY_NAME_LOWER}Service.remove(id);
  }
}
EOF

# Update Module
echo "📄 Updating Module..."
cat > src/$ENTITY_NAME_LOWER/$ENTITY_NAME_LOWER.module.ts << EOF
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ${ENTITY_NAME}Controller } from './$ENTITY_NAME_LOWER.controller';
import { ${ENTITY_NAME}Service } from './$ENTITY_NAME_LOWER.service';
import { $ENTITY_NAME } from './entities/$ENTITY_NAME_LOWER.entity';
import { ${ENTITY_NAME}Repository } from './repositories/$ENTITY_NAME_LOWER.repository';

@Module({
  imports: [TypeOrmModule.forFeature([$ENTITY_NAME])],
  controllers: [${ENTITY_NAME}Controller],
  providers: [${ENTITY_NAME}Service, ${ENTITY_NAME}Repository],
  exports: [${ENTITY_NAME}Service, ${ENTITY_NAME}Repository],
})
export class ${ENTITY_NAME}Module {}
EOF

# Update App Module
echo "📄 Updating App Module..."

# Check if entity import already exists
if ! grep -q "import { $ENTITY_NAME }" src/app.module.ts; then
    # Add import for new entity
    sed -i.bak "/import.*entity';/a\\
import { $ENTITY_NAME } from './$ENTITY_NAME_LOWER/entities/$ENTITY_NAME_LOWER.entity';
" src/app.module.ts
    
    # Add entity to entities array
    sed -i.bak "s/entities: \[/entities: [\n      $ENTITY_NAME,/" src/app.module.ts
    
    # Remove backup file
    rm -f src/app.module.ts.bak
fi

echo ""
echo "✅ Module $ENTITY_NAME created successfully!"
echo ""
echo "📋 Fields created:"
for field in "${FIELDS[@]}"; do
    echo "   - $field"
done
echo ""
echo "📂 Created files:"
echo "   - src/$ENTITY_NAME_LOWER/entities/$ENTITY_NAME_LOWER.entity.ts"
echo "   - src/$ENTITY_NAME_LOWER/dto/create-$ENTITY_NAME_LOWER.dto.ts"
echo "   - src/$ENTITY_NAME_LOWER/dto/update-$ENTITY_NAME_LOWER.dto.ts"
echo "   - src/$ENTITY_NAME_LOWER/dto/response-$ENTITY_NAME_LOWER.dto.ts"
echo "   - src/$ENTITY_NAME_LOWER/repositories/$ENTITY_NAME_LOWER.repository.ts"
echo "   - src/$ENTITY_NAME_LOWER/$ENTITY_NAME_LOWER.service.ts"
echo "   - src/$ENTITY_NAME_LOWER/$ENTITY_NAME_LOWER.controller.ts"
echo "   - src/$ENTITY_NAME_LOWER/$ENTITY_NAME_LOWER.module.ts"
echo ""
echo "🔗 API Endpoints:"
echo "   POST   http://localhost:3000/${ENTITY_NAME_LOWER}s"
echo "   GET    http://localhost:3000/${ENTITY_NAME_LOWER}s"
echo "   GET    http://localhost:3000/${ENTITY_NAME_LOWER}s/stats"
echo "   GET    http://localhost:3000/${ENTITY_NAME_LOWER}s/:id"
echo "   PATCH  http://localhost:3000/${ENTITY_NAME_LOWER}s/:id"
echo "   DELETE http://localhost:3000/${ENTITY_NAME_LOWER}s/:id"
echo ""
echo "🚀 Restart your server: npm run start:dev"
echo ""
echo "💡 Supported field types:"
echo "   string, text, number, boolean, email, date, url, array, enum:value1,value2"
