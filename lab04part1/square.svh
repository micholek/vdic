class square extends rectangle;
    function new(real side);
        super.new(side, side);
    endfunction : new

    function void print();
        $display("Square w=%g area=%g", width, get_area());
    endfunction : print
endclass : square
