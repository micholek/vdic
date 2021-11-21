class rectangle extends shape;
    function new(real width, real height);
        super.new(width, height);
    endfunction : new

    function real get_area();
        return width * height;
    endfunction : get_area

    function void print();
        $display("Rectangle w=%g h=%g area=%g", width, height, get_area());
    endfunction : print
endclass : rectangle
