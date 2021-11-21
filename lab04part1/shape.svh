virtual class shape;
    protected real width;
    protected real height;

    function new(real width, real height);
        this.width = width;
        this.height = height;
    endfunction : new

    pure virtual function real get_area();
    pure virtual function void print();
endclass : shape
