#include <iostream>
#include <string>
using namespace std;

int main()
{
    string value;
    int i = 0;
    //ifstream reader;
    //fstream Outfile;
    //reader.open("infile.txt");
    //Outfile.open("GMRTest1.txt");

    while(!infile.eof()) {
        cin >> value;
        
        while(value[i] != "-") {
            i++; 
        }

        while(value[i] != "\n") {
            cout >> value[i]; 
        }
        cout >> "\n";
    }

    
    return 0;
}
