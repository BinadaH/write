/*
How to use MuPDF to render a single page and print the result as
a PPM to stdout.
To build this example in a source tree and render first page at
100% zoom with no rotation, run:
make examples
./build/debug/example document.pdf 1 100 0 > page1.ppm
To build from installed sources, and render the same document, run:
gcc -I/usr/local/include -o example \
/usr/local/share/doc/mupdf/examples/example.c \
/usr/local/lib/libmupdf.a \
/usr/local/lib/libmupdfthird.a \
-lm
./example document.pdf 1 100 0 > page1.ppm
*/
#include <mupdf/fitz.h>
#include <stdio.h>
#include <stdlib.h>
#include <format>
int main(int argc, char** argv)
{
	char* input;
	float zoom, rotate;
	int page_count;
	fz_context* ctx;
	fz_document* doc;
	fz_pixmap* pix;
	fz_matrix ctm;

	int x, y;

	input = argv[1];
	zoom = argc > 2 ? atof(argv[2]) : 100;
	rotate = argc > 3 ? atof(argv[3]) : 0;
	
	ctx = fz_new_context(NULL, NULL, FZ_STORE_UNLIMITED);
	if (!ctx)
	{
		fprintf(stderr, "cannot create mupdf context\n");
		return EXIT_FAILURE;
	}
	/* Register the default file types to handle. */
	fz_try(ctx)
		fz_register_document_handlers(ctx);
	fz_catch(ctx)
	{
		fz_report_error(ctx);
		fprintf(stderr, "cannot register document handlers\n");
		fz_drop_context(ctx);
		return EXIT_FAILURE;
	}
	/* Open the document. */
	fz_try(ctx)
		doc = fz_open_document(ctx, input);
	fz_catch(ctx)
	{
		fz_report_error(ctx);
		fprintf(stderr, "cannot open document\n");
		fz_drop_context(ctx);
		return EXIT_FAILURE;
	}
	/* Count the number of pages. */
	fz_try(ctx)
		page_count = fz_count_pages(ctx, doc);
	fz_catch(ctx)
	{
		fz_report_error(ctx);
		fprintf(stderr, "cannot count number of pages\n");
		fz_drop_document(ctx, doc);
		fz_drop_context(ctx);
		return EXIT_FAILURE;
	}

	/* Compute a transformation matrix for the zoom and rotation desired. */
	/* The default resolution without scaling is 72 dpi. */
	ctm = fz_scale(zoom / 100, zoom / 100);
	ctm = fz_pre_rotate(ctm, rotate);
	/* Render page to an RGB pixmap. */
	for (int i = 0; i < page_count; i++) {
		fz_try(ctx)
			pix = fz_new_pixmap_from_page_number(ctx, doc, i, ctm, fz_device_rgb(ctx), 0);
		fz_catch(ctx)
		{
			fz_report_error(ctx);
			fprintf(stderr, "cannot render page\n");
			fz_drop_document(ctx, doc);
			fz_drop_context(ctx);
			return EXIT_FAILURE;
		}

		fz_save_pixmap_as_png(ctx, pix, std::format("{}_{}.png", input, i).c_str());
		fz_drop_pixmap(ctx, pix);
	}

	/* Clean up. */
	
	fz_drop_document(ctx, doc);
	fz_drop_context(ctx);
	return EXIT_SUCCESS;
}

