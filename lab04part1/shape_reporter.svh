class shape_reporter #(type T = shape);

    protected static T shape_storage[$];

    static function void push_shape(T shape);
        shape_storage.push_back(shape);
    endfunction : push_shape

    static function void report_shapes();
        real total_area = 0;
        foreach (shape_storage[i]) begin
            shape_storage[i].print();
            total_area += shape_storage[i].get_area();
        end
        $display("Total area: %g\n", total_area);
    endfunction : report_shapes

endclass : shape_reporter
