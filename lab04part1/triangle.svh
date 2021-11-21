class triangle extends shape;
    function new(real width, real height);
        super.new(width, height);
    endfunction : new

    function real get_area();
        return 0.5 * width * height;
    endfunction : get_area

    function void print();
        $display("Triangle w=%g h=%g area=%g", width, height, get_area());
    endfunction : print
endclass : triangle
