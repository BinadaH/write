workspace "pdf2img"
	configurations {"Debug", "Release"}
	location ("build")
	architecture ("x86_64")

project "pdf2img"
	targetdir ("bin")
	kind "ConsoleApp"
	language "C++"
	files {
		"src/**.h",
		"src/**.cpp"
	}
	includedirs {
		"libs/mupdflib/include"
	}
	
	
	filter "system:windows"
		libdirs {"libs/mupdflib/win-x64"}
		links { 
			"libmupdf.lib",
		}
	filter "system:linux"
		libdirs {"libs/mupdflib/linux-x64"}
		links { "libmupdf.a" }


