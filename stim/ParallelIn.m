function [received] = ParallelIn()
    % This function reads two 8-bit parallel port inputs using `parport`,
    % decodes them into binary arrays, and concatenates them into a 16-bit array.

    % Read the first parallel port (base address 0x3FD0 or 16392 in decimal).
    % The value is inverted with (255 - value) to match expected logic levels.
    rawinput = 255 - parport(16392);
    
    % Initialize an 8-bit array to store the decoded bits.
    received = [0,0,0,0,0,0,0,0]; % [trig, bnc, bnc, r_thumb, r_index, r_middle, r_ring, r_pinkie]

    % Start with the highest bit power (2^7 = 128).
    power = 7;

    % Loop to decode rawinput into individual bits.
    for i = 1:length(received)
        if rawinput >= 2^power
            received(i) = 1;
            rawinput = rawinput - 2^power;  % Subtract the value of the bit just set.
        end
        power = power - 1;  % Move to the next lower bit.
    end

    % Read the second parallel port (address 0x2008 or 8200 in decimal).
    rawinput2 = 255 - parport(8200);

    % Initialize a second 8-bit binary array.
    received2 = [0,0,0,0,0,0,0,0]; % [trig, bnc, bnc, l_thumb, l_index, l_middle, l_ring, l_pinkie]
    power = 7;

    % Decode the second input into bits.
    for i = 1:length(received2)
        if rawinput2 >= 2^power
            received2(i) = 1;
            rawinput2 = rawinput2 - 2^power;
        end
        power = power - 1;
    end

    % Concatenate both 8-bit arrays into a single 16-bit array.
    received = [received, received2];
end