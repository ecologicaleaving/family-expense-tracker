// Supabase Edge Function for receipt scanning using Google Cloud Vision API
// Extracts amount, date, and merchant information from receipt images

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const GOOGLE_VISION_API_URL = "https://vision.googleapis.com/v1/images:annotate";

interface ScanResult {
  amount: number | null;
  date: string | null;
  merchant: string | null;
  confidence: number;
  rawText: string;
}

interface ErrorResponse {
  error: string;
  code: string;
}

// Italian date patterns
const datePatterns = [
  // DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
  /(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})/,
  // DD/MM/YY
  /(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2})/,
  // DD MMM YYYY (e.g., 15 DIC 2024)
  /(\d{1,2})\s+(GEN|FEB|MAR|APR|MAG|GIU|LUG|AGO|SET|OTT|NOV|DIC)\w*\s+(\d{4})/i,
];

// Italian month abbreviations
const monthMap: Record<string, string> = {
  'GEN': '01', 'GENNAIO': '01',
  'FEB': '02', 'FEBBRAIO': '02',
  'MAR': '03', 'MARZO': '03',
  'APR': '04', 'APRILE': '04',
  'MAG': '05', 'MAGGIO': '05',
  'GIU': '06', 'GIUGNO': '06',
  'LUG': '07', 'LUGLIO': '07',
  'AGO': '08', 'AGOSTO': '08',
  'SET': '09', 'SETTEMBRE': '09',
  'OTT': '10', 'OTTOBRE': '10',
  'NOV': '11', 'NOVEMBRE': '11',
  'DIC': '12', 'DICEMBRE': '12',
};

// Amount patterns for Italian receipts
const amountPatterns = [
  // EUR or € followed by amount
  /(?:EUR|€)\s*(\d+[,\.]\d{2})/i,
  // TOTALE or TOT followed by amount
  /(?:TOTALE|TOT\.?|TOTAL)\s*[:=]?\s*(?:EUR|€)?\s*(\d+[,\.]\d{2})/i,
  // Amount followed by EUR or €
  /(\d+[,\.]\d{2})\s*(?:EUR|€)/i,
  // DA PAGARE or IMPORTO
  /(?:DA PAGARE|IMPORTO|PAGATO)\s*[:=]?\s*(?:EUR|€)?\s*(\d+[,\.]\d{2})/i,
  // Standalone amount at end of line (common for totals)
  /^\s*(\d+[,\.]\d{2})\s*$/m,
];

function extractAmount(text: string): number | null {
  for (const pattern of amountPatterns) {
    const match = text.match(pattern);
    if (match) {
      // Convert Italian format (comma as decimal) to number
      const amountStr = match[1].replace(',', '.');
      const amount = parseFloat(amountStr);
      if (!isNaN(amount) && amount > 0 && amount < 100000) {
        return amount;
      }
    }
  }
  return null;
}

function extractDate(text: string): string | null {
  for (const pattern of datePatterns) {
    const match = text.match(pattern);
    if (match) {
      let day: string, month: string, year: string;

      if (pattern.source.includes('GEN|FEB')) {
        // Italian month name format
        day = match[1].padStart(2, '0');
        const monthStr = match[2].toUpperCase().substring(0, 3);
        month = monthMap[monthStr] || '01';
        year = match[3];
      } else {
        day = match[1].padStart(2, '0');
        month = match[2].padStart(2, '0');
        year = match[3].length === 2 ? '20' + match[3] : match[3];
      }

      // Validate date
      const dateStr = `${year}-${month}-${day}`;
      const parsedDate = new Date(dateStr);
      if (!isNaN(parsedDate.getTime())) {
        return dateStr;
      }
    }
  }
  return null;
}

function extractMerchant(text: string): string | null {
  // Split into lines and look for merchant name
  const lines = text.split('\n').map(l => l.trim()).filter(l => l.length > 0);

  // Common patterns to skip
  const skipPatterns = [
    /^(SCONTRINO|RICEVUTA|DOCUMENTO|FISCALE)/i,
    /^(P\.IVA|P\.I\.|C\.F\.|REG\.)/i,
    /^(DATA|ORA|CASSA)/i,
    /^(TOTALE|TOT|SUBTOT|RESTO)/i,
    /^\d+[,\.]\d{2}$/,
    /^[\d\/\-\.]+$/,
  ];

  // First few non-skipped lines are likely the merchant name
  for (const line of lines.slice(0, 5)) {
    const shouldSkip = skipPatterns.some(p => p.test(line));
    if (!shouldSkip && line.length >= 3 && line.length <= 50) {
      // Clean up the merchant name
      const cleaned = line
        .replace(/[^\w\s\-\'àèéìòù]/gi, '')
        .trim();
      if (cleaned.length >= 3) {
        return cleaned;
      }
    }
  }

  return null;
}

function calculateConfidence(result: ScanResult): number {
  let score = 0;
  let factors = 0;

  if (result.amount !== null) {
    score += 40;
    factors++;
  }
  if (result.date !== null) {
    score += 30;
    factors++;
  }
  if (result.merchant !== null) {
    score += 30;
    factors++;
  }

  // Bonus for having all fields
  if (factors === 3) {
    score += 10;
  }

  return Math.min(score, 100);
}

async function callGoogleVisionAPI(imageBase64: string, apiKey: string): Promise<string> {
  const requestBody = {
    requests: [
      {
        image: {
          content: imageBase64,
        },
        features: [
          {
            type: "TEXT_DETECTION",
            maxResults: 1,
          },
        ],
        imageContext: {
          languageHints: ["it"],
        },
      },
    ],
  };

  const response = await fetch(`${GOOGLE_VISION_API_URL}?key=${apiKey}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Google Vision API error: ${error}`);
  }

  const data = await response.json();
  const textAnnotations = data.responses?.[0]?.textAnnotations;

  if (!textAnnotations || textAnnotations.length === 0) {
    throw new Error("No text detected in image");
  }

  return textAnnotations[0].description || "";
}

serve(async (req: Request) => {
  // CORS headers
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Get Google Vision API key from environment
    const apiKey = Deno.env.get("GOOGLE_VISION_API_KEY");
    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: "Google Vision API key not configured", code: "config_error" } as ErrorResponse),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Parse request body
    const { image } = await req.json();

    if (!image) {
      return new Response(
        JSON.stringify({ error: "No image provided", code: "invalid_request" } as ErrorResponse),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Remove data URL prefix if present
    const base64Image = image.replace(/^data:image\/\w+;base64,/, "");

    // Call Google Vision API
    const extractedText = await callGoogleVisionAPI(base64Image, apiKey);

    // Parse the extracted text
    const result: ScanResult = {
      amount: extractAmount(extractedText),
      date: extractDate(extractedText),
      merchant: extractMerchant(extractedText),
      confidence: 0,
      rawText: extractedText,
    };

    // Calculate confidence score
    result.confidence = calculateConfidence(result);

    return new Response(
      JSON.stringify(result),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("Error processing receipt:", error);

    const errorMessage = error instanceof Error ? error.message : "Unknown error";

    return new Response(
      JSON.stringify({
        error: `Failed to process receipt: ${errorMessage}`,
        code: "processing_error"
      } as ErrorResponse),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
