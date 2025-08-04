export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      generation_parameters: {
        Row: {
          base_weekly_km: number
          goal: Database["public"]["Enums"]["training_goal"]
          id: string
          level: Database["public"]["Enums"]["training_level"]
          peak_multiplier: number
          volume_reduction_peak: number
        }
        Insert: {
          base_weekly_km: number
          goal: Database["public"]["Enums"]["training_goal"]
          id?: string
          level: Database["public"]["Enums"]["training_level"]
          peak_multiplier: number
          volume_reduction_peak?: number
        }
        Update: {
          base_weekly_km?: number
          goal?: Database["public"]["Enums"]["training_goal"]
          id?: string
          level?: Database["public"]["Enums"]["training_level"]
          peak_multiplier?: number
          volume_reduction_peak?: number
        }
        Relationships: []
      }
      planned_sessions: {
        Row: {
          day_of_week: number
          id: string
          scheduled_date: string
          status: string
          week_id: string
          workout_details: Json
        }
        Insert: {
          day_of_week: number
          id?: string
          scheduled_date: string
          status?: string
          week_id: string
          workout_details: Json
        }
        Update: {
          day_of_week?: number
          id?: string
          scheduled_date?: string
          status?: string
          week_id?: string
          workout_details?: Json
        }
        Relationships: [
          {
            foreignKeyName: "planned_sessions_week_id_fkey"
            columns: ["week_id"]
            isOneToOne: false
            referencedRelation: "planned_weeks"
            referencedColumns: ["id"]
          },
        ]
      }
      planned_weeks: {
        Row: {
          id: string
          key_workouts: Json
          phase: Database["public"]["Enums"]["training_phase"]
          plan_id: string
          start_date: string
          target_km: number
          week_number: number
          zone_distribution: Json
        }
        Insert: {
          id?: string
          key_workouts: Json
          phase: Database["public"]["Enums"]["training_phase"]
          plan_id: string
          start_date: string
          target_km: number
          week_number: number
          zone_distribution: Json
        }
        Update: {
          id?: string
          key_workouts?: Json
          phase?: Database["public"]["Enums"]["training_phase"]
          plan_id?: string
          start_date?: string
          target_km?: number
          week_number?: number
          zone_distribution?: Json
        }
        Relationships: [
          {
            foreignKeyName: "planned_weeks_plan_id_fkey"
            columns: ["plan_id"]
            isOneToOne: false
            referencedRelation: "user_training_plans"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          avatar_url: string | null
          bio: string | null
          created_at: string
          display_name: string | null
          id: string
          is_active: boolean
          preferences: Json
          updated_at: string
          username: string
        }
        Insert: {
          avatar_url?: string | null
          bio?: string | null
          created_at?: string
          display_name?: string | null
          id?: string
          is_active?: boolean
          preferences?: Json
          updated_at?: string
          username: string
        }
        Update: {
          avatar_url?: string | null
          bio?: string | null
          created_at?: string
          display_name?: string | null
          id?: string
          is_active?: boolean
          preferences?: Json
          updated_at?: string
          username?: string
        }
        Relationships: []
      }
      user_training_plans: {
        Row: {
          created_at: string
          duration_weeks: number
          goal: Database["public"]["Enums"]["training_goal"]
          id: string
          is_active: boolean
          level: Database["public"]["Enums"]["training_level"]
          peak_weekly_km: number
          phase_distribution: Json
          sessions_per_week: number
          target_date: string
          user_data: Json
          user_id: string
        }
        Insert: {
          created_at?: string
          duration_weeks: number
          goal: Database["public"]["Enums"]["training_goal"]
          id?: string
          is_active?: boolean
          level: Database["public"]["Enums"]["training_level"]
          peak_weekly_km: number
          phase_distribution: Json
          sessions_per_week: number
          target_date: string
          user_data?: Json
          user_id: string
        }
        Update: {
          created_at?: string
          duration_weeks?: number
          goal?: Database["public"]["Enums"]["training_goal"]
          id?: string
          is_active?: boolean
          level?: Database["public"]["Enums"]["training_level"]
          peak_weekly_km?: number
          phase_distribution?: Json
          sessions_per_week?: number
          target_date?: string
          user_data?: Json
          user_id?: string
        }
        Relationships: []
      }
      workout_rules: {
        Row: {
          created_at: string
          id: string
          rule_data: Json
          rule_type: string
        }
        Insert: {
          created_at?: string
          id?: string
          rule_data: Json
          rule_type: string
        }
        Update: {
          created_at?: string
          id?: string
          rule_data?: Json
          rule_type?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      training_goal: "5k" | "10k" | "half_marathon" | "marathon"
      training_level: "beginner" | "intermediate" | "advanced"
      training_phase: "build" | "intensity" | "specificity" | "peak"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {
      training_goal: ["5k", "10k", "half_marathon", "marathon"],
      training_level: ["beginner", "intermediate", "advanced"],
      training_phase: ["build", "intensity", "specificity", "peak"],
    },
  },
} as const

