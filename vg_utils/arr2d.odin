package vg_utils

import "core:fmt"
import "core:os"
import "core:strings"

Arr2d :: struct($T: typeid) {
	data: [dynamic]T,
	sx: 	  int,
	sy: 	  int,
}

arr2d_make :: proc($T: typeid, x: int, y: int) -> Arr2d(T) {
	arr: Arr2d(T) = ---
	arr.data = make([dynamic]T, x * y)
	arr.sx = x
	arr.sy = y
	return arr
}

arr2d_get_ptr :: proc(arr: ^Arr2d($T), x: int, y: int) -> ^T {
	return &arr.data[y * x + x]
}

arr2d_get_val :: proc(arr: ^Arr2d($T), x: int, y: int) -> T {
	return arr.data[y * x + x]
}

dump_to_file_fmt :: proc(arr: ^Arr2d($T), path: string) -> (success: bool) {
	fd, err := os.open(path, os.O_WRONLY | os.O_CREATE | os.O_TRUNC)

	if err != 0 {
		fmt.printf("Failed to open %s (%d)\n", path, err)
		return false
	}

	ret := fmt.fprintf(fd, "%#v", arr) 
	fmt.printf("%v", ret)
	return true
}

dump_to_file_printer :: proc(arr: ^Arr2d($T), path: string, printer: proc(bl: ^strings.Builder, el: ^T)) -> (success: bool) {
	bl := strings.make_builder() 
	for y := 0; y < arr.sy; y += 1 {
		for x := 0; x < arr.sx; x += 1 {
			el := get_ptr(arr, x, y)
			printer(&bl, el)
			fmt.sbprintf(&bl, " ")
		}
		fmt.sbprintf(&bl, "\n")
	}

	fd, err := os.open(path, os.O_WRONLY | os.O_CREATE | os.O_TRUNC)
	if err != 0 {
		fmt.printf("Failed to open %s (%d)\n", path, err)
		return false
	}

	ret := fmt.fprintf(fd, "%s", bl.buf)
	return true 
}

get :: proc { 
 	arr2d_get_val, 
}

get_ptr :: proc {
	arr2d_get_ptr,
}

dump_to_file :: proc { 
	dump_to_file_fmt,
	dump_to_file_printer,
}