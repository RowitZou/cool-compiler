#include <iostream>
#include <functional>

using std::cout;
using std::endl;

class A{
public:
    char a;
    void f(){
    };
};

class B1: public A{
public:
    char b1;
};

class B2: public A{
public:
    char b2;
};

class B3: public virtual A{
public:
    char b3;
};

class B4: public virtual A{
public:
    char b4;
};

class C1: public B1,public B2{
public:
    char c1;
};

class C2: public B3,public B4{
public:
    char c2;
};

main(){
    C1 c1;
    C2 c2;

    c1.B1::a = 'a';
    c1.B2::a = 'a';
    c1.b1 = 'b';
    c1.b2 = 'b';
    c1.c1 = 'c';
    c1.B1::f();
    c1.B2::f();

    cout << "not virtual" << endl;
    cout << "c1:    " << reinterpret_cast<int*>(&(c1)) << endl;
    cout << "B1::a: " << reinterpret_cast<int*>(&(c1.B1::a)) << endl;
    cout << "b1:    " << reinterpret_cast<int*>(&(c1.b1)) << endl;
    cout << "B2::a: " << reinterpret_cast<int*>(&(c1.B2::a)) << endl;
    cout << "b2:    " << reinterpret_cast<int*>(&(c1.b2)) << endl;
    cout << "c1:c1  " << reinterpret_cast<int*>(&(c1.c1)) << endl;
    cout << "B1::f: " << (void*)(&C1::B1::f) << endl;
    cout << "B2::f: " << (void*)(&C1::B2::f) << endl;

    c2.a = 'a';
    c2.b3 = 'b';
    c2.b4 = 'b';
    c2.c2 = 'c';
    c2.f();

    cout << "virtual" << endl;
    cout << "c2:    " << reinterpret_cast<int*>(&(c2)) << endl;
    cout << "b3:    " << reinterpret_cast<int*>(&(c2.b3)) << endl;
    cout << "b4:    " << reinterpret_cast<int*>(&(c2.b4)) << endl;
    cout << "c2:c2: " << reinterpret_cast<int*>(&(c2.c2)) << endl;
    cout << "a:     " << reinterpret_cast<int*>(&(c2.a)) << endl;
    cout << "f:     " << (void*)(&C2::f) << endl;
}

