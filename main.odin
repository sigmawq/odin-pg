	package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:sys/win32"
import "vendor:glfw"
import gl "vendor:OpenGL"
import "vg_utils"


Bar :: struct {
	a: f32,
	b: i64,
	c: i64,
}

soa_test :: proc() {
	b: #soa [dynamic]Bar
	some_bar := Bar { 333.0, 10, 20 }
	append_soa_elem(&b, some_bar)

	fmt.printf("\n--- SOA TEST ---\n%#v\n", b)
}

load_shaders :: proc(vertex: string, fragment: string) -> (prog_id: u32) {
	vs_id := gl.CreateShader(gl.VERTEX_SHADER)
	fs_id := gl.CreateShader(gl.FRAGMENT_SHADER)

	vs_source, success := os.read_entire_file_from_filename(vertex, context.allocator)
	vs_source_string := string(vs_source)
	vs_source_cstring := strings.clone_to_cstring(vs_source_string, context.allocator)
	fmt.printf("%v", vs_source_cstring)
	if !success {
		fmt.printf("Failed to load vs source %v", vertex)
	}

	fs_source, success2 := os.read_entire_file_from_filename(fragment, context.allocator)
	fs_source_string := string(fs_source)
	fs_source_cstring := strings.clone_to_cstring(fs_source_string, context.allocator)
	if !success2 {
		fmt.printf("Failed to load fs source %v", fragment)
	}

	result: i32 = 0
	info_log_length: i32

	gl.ShaderSource(vs_id, 1, &vs_source_cstring, nil);
	gl.CompileShader(vs_id);

	gl.GetShaderiv(vs_id, gl.COMPILE_STATUS, &result);
	gl.GetShaderiv(vs_id, gl.INFO_LOG_LENGTH, &info_log_length);
	if result == 0 {
		err_msg := make([]byte, info_log_length + 1, context.temp_allocator)
		gl.GetShaderInfoLog(vs_id, info_log_length, nil, cast([^]byte)(&err_msg[0]))
		fmt.printf("Error compiling VS: %s (%d)", err_msg, info_log_length)
		os.exit(-1)
		// std::vector<char> VertexShaderErrorMessage(InfoLogLength+1);
		// glGetShaderInfoLog(VertexShaderID, InfoLogLength, NULL, &VertexShaderErrorMessage[0]);
		// printf("%s\n", &VertexShaderErrorMessage[0]);
	}

	gl.ShaderSource(fs_id, 1, &fs_source_cstring, nil);
	gl.CompileShader(fs_id);

	gl.GetShaderiv(fs_id, gl.COMPILE_STATUS, &result);
	gl.GetShaderiv(fs_id, gl.INFO_LOG_LENGTH, &info_log_length);
	if result == 0 {
		err_msg := make([]byte, info_log_length + 1, context.temp_allocator)
		gl.GetProgramInfoLog(fs_id, info_log_length, nil, cast([^]byte)(&err_msg[0]))
		fmt.printf("Error compiling FS: %s", err_msg)
		os.exit(-1)
		// std::vector<char> VertexShaderErrorMessage(InfoLogLength+1);
		// glGetShaderInfoLog(VertexShaderID, InfoLogLength, NULL, &VertexShaderErrorMessage[0]);
		// printf("%s\n", &VertexShaderErrorMessage[0]);
	}

	program_id: u32 = gl.CreateProgram();
	gl.AttachShader(program_id, vs_id);
	gl.AttachShader(program_id, fs_id);
	gl.LinkProgram(program_id);

	// Check the program
	gl.GetProgramiv(program_id, gl.LINK_STATUS, &result);
	gl.GetProgramiv(program_id, gl.INFO_LOG_LENGTH, &info_log_length);
	if result == 0 {
		err_msg := make([]byte, info_log_length + 1, context.temp_allocator)
		gl.GetProgramInfoLog(program_id, info_log_length, nil, cast([^]byte)(&err_msg[0]))
		fmt.printf("Failed to compile gl program: %s (%d)", err_msg, info_log_length)
		// std::vector<char> ProgramErrorMessage(InfoLogLength+1);
		// glGetProgramInfoLog(ProgramID, InfoLogLength, NULL, &ProgramErrorMessage[0]);
		// printf("%s\n", &ProgramErrorMessage[0]);
	}
	
	gl.DeleteShader(vs_id);
	gl.DeleteShader(fs_id);

	return program_id
}
	
main :: proc() {
	using vg_utils
	using strings

	// v := arr2d_make(f64, 8, 2)
	
	// get(&v, 0, 0)

	// printer_custom :: proc(sb: ^strings.Builder, el: ^f64) {
	// 	fmt.sbprintf(sb, "%v", el^)
	// }

	// dump_to_file(&v, "dump.txt", printer_custom)
	// dump_to_file(&v, "dump2.txt", printer_custom)

	// bl := make_builder()
	// fmt.sbprintf(&bl, "%v ", 5000)
	// fmt.sbprintf(&bl, "%v ", 501)
	// fmt.sbprintf(&bl, "%v ", 502)

	// fmt.printf("%s", bl.buf)

	// test := win32.get_current_thread_id()

	// fmt.printf("%d\n", size_of(f32))

	if glfw.Init() == 0 {
		fmt.printf("GLFW failed to initialize!\n")
		os.exit(-1)
	}	
	else {
		maj, min, rev := glfw.GetVersion()
		fmt.printf("GLFW: %v.%v.%v\n", maj, min, rev)
	}

	window := glfw.CreateWindow(640, 480, "Hello world!", nil, nil)

	if window == nil {
		fmt.printf("Failed to create glfw window!\n")
	}

	glfw.MakeContextCurrent(window)

	gl.load_up_to(4, 5, proc(p: rawptr, name: cstring) do (cast(^rawptr)p)^ = glfw.GetProcAddress(name); );

	vao: u32
	gl.GenVertexArrays(1, &vao);
	gl.BindVertexArray(vao);  

	verticies: []f32 = { 
		-0.5, -0.5, 0.0,
     	0.5, -0.5, 0.0,
     	0.0,  0.5, 0.0,
	}

	vb: u32
	gl.GenBuffers(1, &vb)

	gl.BindBuffer(gl.ARRAY_BUFFER, vb)

	fmt.printf("\n%v\n", len(verticies) * size_of(f32))
	gl.BufferData(gl.ARRAY_BUFFER, len(verticies) * size_of(f32), cast(rawptr)&(verticies[0]), gl.STATIC_DRAW)

	gl.VertexAttribPointer(
		0,
		3,
		gl.FLOAT,
		gl.FALSE,
		3 * size_of(f32),
		0,
	)

	gl.EnableVertexAttribArray(0)

	program_id := load_shaders("shaders\\shader_vertex.glsl", "shaders\\shader_fragment.glsl")
	fmt.printf("program id %v\n", program_id)
	gl.UseProgram(program_id)
    gl.ClearColor(0.2, 0.3, 0.3, 1.0);
	for !glfw.WindowShouldClose(window)
    {
        gl.Clear(gl.COLOR_BUFFER_BIT);

    	gl.BindVertexArray(vao);
        /* Render here */
        gl.DrawArrays(gl.TRIANGLES, 0, 3); // Starting from vertex 0; 3 vertices total -> 1 triangle
		// gl.DisableVertexAttribArray(0);

        // Swap front and back buffers 
        glfw.SwapBuffers(window);

        /* Poll for and process events */
        glfw.PollEvents();
    }

    glfw.Terminate();
}