#!/usr/bin/ruby -w

def generate_source(offset)
    header = %s{
#include <stdio.h>

typedef int (*function_t)(void);

int i = 1;

int func(void) {
    i++;
    i++;
    i++;
    printf("%d\n", i);
    return i;
}

int main(int argc, char **argv) \{
    int offset = }
    
    footer = %{
    function_t f = &func + offset;
    printf("%d\\n", f());
    return 0;
\}
}
    "#{header}#{offset};#{footer}"
end

(2**32).times do |i|
    output = File.open("test.c", "w+")
    output.print generate_source(i)
    output.close
    
    system "gcc -Wall -o test test.c"
    if `./test 2>&1` !~ /Segmentation fault/
        puts i
    end
end
