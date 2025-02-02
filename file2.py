class Animal:
    
    def __init__(self, name,age):
        self.name =name
        self.age=age

class Dog(Animal):
    def __init__(self, name, age):
        super().__init__(name, age)

     
# adfkjasd