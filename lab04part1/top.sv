module top;

    initial begin
        int shapes_fd;
        string shape_type;
        real width;
        real height;

        shapes_fd = $fopen("lab04part1_shapes.txt", "r");
        while (!$feof(shapes_fd)) begin
            if ($fscanf(shapes_fd, "%s %g %g\n", shape_type, width, height) != 3) begin
                $fatal(2, {"Invalid format of shapes file"});
            end
            void'(shape_factory::make_shape(shape_type, width, height));
        end
        $fclose(shapes_fd);

        shape_reporter#(rectangle)::report_shapes();
        shape_reporter#(square)::report_shapes();
        shape_reporter#(triangle)::report_shapes();
    end

endmodule : top
