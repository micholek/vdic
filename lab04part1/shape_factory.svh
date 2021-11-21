class shape_factory;

    static function shape make_shape(string shape_type, real width, real height);
        rectangle rectangle_h;
        square square_h;
        triangle triangle_h;

        case (shape_type)
            "rectangle" : begin
                rectangle_h = new(width, height);
                return rectangle_h;
            end

            "square" : begin
                square_h = new(width);
                return square_h;
            end

            "triangle" : begin
                triangle_h = new(width, height);
                return triangle_h;
            end

            default : begin
                $fatal(1, {"No such shape: ", shape_type});
            end
        endcase
    endfunction : make_shape

endclass : shape_factory
