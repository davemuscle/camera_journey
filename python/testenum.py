
def print_value(val):
    print(val)
    
class Poopies:
    
    color = 'brown'
    taste = 'good'

    def m(self,p):
        print(p)
        
    @property
    def p(self):
        print("Hey")
        return self._p
        
    @p.setter
    def p(self,value):
        self._p = value
        self.m(value)
        
    @property
    def q(self):
        print("Reading Q")
        return self._q
        
    @q.setter
    def q(self,value):
        self._q = value
        print("Setting Q");
    
    def __init__(self):
        print("init")
        
my = Poopies()
print(my.color)
print(my.taste)

my.color = 'green'
print(my.color)
print(my.taste)

my.p = 3
x = my.p

my.q = 1
print(my.q)