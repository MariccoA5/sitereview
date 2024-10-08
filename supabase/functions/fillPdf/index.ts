import { serve } from "https://deno.land/std@0.106.0/http/server.ts";

// PDF Filler API base URL
const PDF_FILLER_BASE_URL = "http://your-pdf-filler-instance-url";

// Supabase Edge function handler
serve(async (req) => {
  try {
    // Extract submitForm data from the request
    const { submitForm } = await req.json();

    // Build the fields data dynamically based on the submitForm object
    const fields = {
      "Text1": submitForm.siteName || "",
      "Text2": submitForm.siteNumber || "",
      "Text3": submitForm.contractor || "",
      "Text4": submitForm.techInitials || "",
      "Text5": submitForm.selectedDate || "",
      "Text6": submitForm.mainComments || "",
      "Check Box19": submitForm.mainCheckbox[0] ? "True" : "False",
      "Comments": submitForm.comments || ""
    };

    // Prepare the payload for the PDF Filler API
    const pdfFillerPayload = {
      pdf: submitForm.pdfUrl, // URL to the PDF to be filled
      fields: fields
    };

    // Send POST request to PDF Filler to fill out the PDF
    const response = await fetch(`${PDF_FILLER_BASE_URL}/fill`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(pdfFillerPayload),
    });

    if (!response.ok) {
      const errorText = await response.text();
      return new Response(errorText, { status: 500 });
    }

    // Parse the response from PDF Filler
    const data = await response.json();

    // Return the filled PDF URL
    return new Response(JSON.stringify({ message: "PDF updated successfully!", pdfUrl: data.url }), {
      headers: { "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error("Error processing the PDF:", error);
    return new Response("Internal Server Error", { status: 500 });
  }
});
