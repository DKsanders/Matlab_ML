% Get which colour user wants to use
function [color] = get_color()
    color = 0;
    while (color ~= 1 && color ~= 2)
        clc;
        disp('Choose color:');
        disp('[1] White');
        disp('[2] Black');
        color = input('Enter 1 or 2: ');
    end
end