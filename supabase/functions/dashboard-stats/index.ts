import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface DashboardRequest {
  group_id: string;
  period: "week" | "month" | "year";
  user_id?: string; // Optional filter by specific member
}

interface CategoryBreakdown {
  category: string;
  total: number;
  count: number;
  percentage: number;
}

interface MemberBreakdown {
  user_id: string;
  display_name: string;
  total: number;
  count: number;
  percentage: number;
}

interface TrendDataPoint {
  date: string;
  total: number;
  count: number;
}

interface DashboardStats {
  period: string;
  start_date: string;
  end_date: string;
  total_amount: number;
  expense_count: number;
  average_expense: number;
  by_category: CategoryBreakdown[];
  by_member: MemberBreakdown[];
  trend: TrendDataPoint[];
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Verify authorization
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Create Supabase client with user's JWT
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    // Get request body
    const { group_id, period, user_id }: DashboardRequest = await req.json();

    if (!group_id || !period) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: group_id, period" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Verify user belongs to the group
    const { data: userData, error: userError } = await supabase.auth.getUser();
    if (userError || !userData.user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("group_id")
      .eq("id", userData.user.id)
      .single();

    if (profileError || profile?.group_id !== group_id) {
      return new Response(
        JSON.stringify({ error: "User does not belong to this group" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Calculate date range based on period
    const now = new Date();
    let startDate: Date;
    const endDate = new Date(now);

    switch (period) {
      case "week":
        startDate = new Date(now);
        startDate.setDate(now.getDate() - 7);
        break;
      case "month":
        startDate = new Date(now);
        startDate.setMonth(now.getMonth() - 1);
        break;
      case "year":
        startDate = new Date(now);
        startDate.setFullYear(now.getFullYear() - 1);
        break;
      default:
        startDate = new Date(now);
        startDate.setMonth(now.getMonth() - 1);
    }

    // Build query for expenses
    let query = supabase
      .from("expenses")
      .select(`
        id,
        amount,
        category,
        expense_date,
        user_id,
        profiles!inner(display_name)
      `)
      .eq("group_id", group_id)
      .gte("expense_date", startDate.toISOString().split("T")[0])
      .lte("expense_date", endDate.toISOString().split("T")[0]);

    // Optional filter by member
    if (user_id) {
      query = query.eq("user_id", user_id);
    }

    const { data: expenses, error: expensesError } = await query;

    if (expensesError) {
      console.error("Error fetching expenses:", expensesError);
      return new Response(
        JSON.stringify({ error: "Failed to fetch expenses" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Calculate totals
    const totalAmount = expenses?.reduce((sum, e) => sum + (e.amount || 0), 0) || 0;
    const expenseCount = expenses?.length || 0;
    const averageExpense = expenseCount > 0 ? totalAmount / expenseCount : 0;

    // Calculate breakdown by category
    const categoryMap = new Map<string, { total: number; count: number }>();
    expenses?.forEach((e) => {
      const cat = e.category || "altro";
      const existing = categoryMap.get(cat) || { total: 0, count: 0 };
      categoryMap.set(cat, {
        total: existing.total + (e.amount || 0),
        count: existing.count + 1,
      });
    });

    const byCategory: CategoryBreakdown[] = Array.from(categoryMap.entries())
      .map(([category, data]) => ({
        category,
        total: Math.round(data.total * 100) / 100,
        count: data.count,
        percentage: totalAmount > 0 ? Math.round((data.total / totalAmount) * 1000) / 10 : 0,
      }))
      .sort((a, b) => b.total - a.total);

    // Calculate breakdown by member
    const memberMap = new Map<string, { display_name: string; total: number; count: number }>();
    expenses?.forEach((e) => {
      const odUserId = e.user_id;
      const displayName = (e.profiles as { display_name: string })?.display_name || "Utente";
      const existing = memberMap.get(odUserId) || { display_name: displayName, total: 0, count: 0 };
      memberMap.set(odUserId, {
        display_name: existing.display_name,
        total: existing.total + (e.amount || 0),
        count: existing.count + 1,
      });
    });

    const byMember: MemberBreakdown[] = Array.from(memberMap.entries())
      .map(([odUserId, data]) => ({
        user_id: odUserId,
        display_name: data.display_name,
        total: Math.round(data.total * 100) / 100,
        count: data.count,
        percentage: totalAmount > 0 ? Math.round((data.total / totalAmount) * 1000) / 10 : 0,
      }))
      .sort((a, b) => b.total - a.total);

    // Calculate trend data
    const trendMap = new Map<string, { total: number; count: number }>();
    expenses?.forEach((e) => {
      const date = e.expense_date;
      const existing = trendMap.get(date) || { total: 0, count: 0 };
      trendMap.set(date, {
        total: existing.total + (e.amount || 0),
        count: existing.count + 1,
      });
    });

    // Fill in missing dates with zeros
    const trend: TrendDataPoint[] = [];
    const currentDate = new Date(startDate);
    while (currentDate <= endDate) {
      const dateStr = currentDate.toISOString().split("T")[0];
      const data = trendMap.get(dateStr) || { total: 0, count: 0 };
      trend.push({
        date: dateStr,
        total: Math.round(data.total * 100) / 100,
        count: data.count,
      });
      currentDate.setDate(currentDate.getDate() + 1);
    }

    // Build response
    const stats: DashboardStats = {
      period,
      start_date: startDate.toISOString().split("T")[0],
      end_date: endDate.toISOString().split("T")[0],
      total_amount: Math.round(totalAmount * 100) / 100,
      expense_count: expenseCount,
      average_expense: Math.round(averageExpense * 100) / 100,
      by_category: byCategory,
      by_member: byMember,
      trend,
    };

    return new Response(JSON.stringify(stats), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Dashboard stats error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
