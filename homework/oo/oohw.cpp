#include<iostream>
using std::cout;

class test_1{
public:
    void fff(int i){
    }
    int gggg(){
        return 1;
    }
};

class test2{
public:
    char kk(char a, int b){
        return 'a';
    }
};

void ssss(char a){
}

main(){
    cout<<"Hello\n";
    test_1 t1;
    test2 t2;
    t1.fff(1);
    t1.gggg();
    t2.kk(1,'a');
    ssss('a');
}
