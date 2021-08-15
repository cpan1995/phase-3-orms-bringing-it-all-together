require "pry"

class Dog
    attr_accessor :id, :name, :breed

    def initialize(attributes)
        attributes.each { |key, value|
            self.send("#{key}=", value)
        }
    end

    def self.create_table
        sql = 
        <<-SQL
            CREATE TABLE IF NOT EXISTS dogs(
                id INTEGER PRIMARY KEY,
                name TEXT,
                breed TEXT
            );
        SQL

        DB[:conn].execute(sql)
    end

    def self.drop_table
        sql = 
            <<-SQL
                DROP TABLE IF EXISTS dogs
            SQL
        DB[:conn].execute(sql)
    end

    def save
        sql= <<-SQL
                INSERT INTO dogs(
                    name,
                    breed
                )
                VALUES( ?, ? )
            SQL
        
        DB[:conn].execute(sql, @name, @breed)
        
        sql_return = <<-SQL
                        SELECT * FROM dogs WHERE name = ?
                    SQL

        @id = DB[:conn].execute(sql_return, @name)[0][0]
        self  
    end

    def self.create(attributes)
        self.new(attributes).save
    end

    def self.new_from_db(row)
        self.new({id: row[0], name: row[1], breed: row[2]})
    end

    def self.all

        sql = <<-SQL
                SELECT * FROM dogs
            SQL
        
        DB[:conn].execute(sql).map { |dog|
           self.new_from_db(dog)
        }
    end

    def self.find_by_name(name)
        sql = <<-SQL
                SELECT * FROM dogs
                WHERE name = ?
                LIMIT 1
            SQL

        DB[:conn].execute(sql, name).map{|dog|
          self.new_from_db(dog)
        }.first
    end

    def self.find(id)

        sql = <<-SQL
                SELECT * FROM dogs
                WHERE id = ?
                LIMIT 1
            SQL
        
        new_dog = DB[:conn].execute(sql, id).map{
            |dog| 
            self.new_from_db(dog)
        }

        new_dog.first

    end

    def self.find_or_create_by(attributes)

        dog = self.create(attributes)

        sql = <<-SQL
                SELECT * FROM dogs
                WHERE name = ? AND breed = ?
                LIMIT 1
            SQL
        found = DB[:conn].execute(sql, dog.name, dog.breed).map{
            |dog|
            self.new_from_db(dog)
        }.first

        if found == []
            dog.save
        else
            return found
        end   
    end

    def update
        sql = <<-SQL
                UPDATE dogs
                SET name = ?,
                    breed = ?
                WHERE 
                    id = ?
            SQL

        DB[:conn].execute(sql, @name, @breed, @id)
    end

end
