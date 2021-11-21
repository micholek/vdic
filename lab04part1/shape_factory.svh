class shape_factory;

    static function shape make_shape(string shape_type, real width, real height);
        rectangle rectangle_h;
        square square_h;
        triangle triangle_h;

        case (shape_type)
            "rectangle" : begin
                rectangle_h = new(width, height);
                shape_reporter#(rectangle)::push_shape(rectangle_h);
                return rectangle_h;
            end

            "square" : begin
                square_h = new(width);
                shape_reporter#(square)::push_shape(square_h);
                return square_h;
            end

            "triangle" : begin
                triangle_h = new(width, height);
                shape_reporter#(triangle)::push_shape(triangle_h);
                return triangle_h;
            end

            default : begin
                $fatal(1, {"No such shape: ", shape_type});
            end
        endcase
    endfunction : make_shape

endclass : shape_factory
