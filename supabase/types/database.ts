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
      expense_payers: {
        Row: {
          expense_id: string
          group_id: string
          member_id: string
          paid_cents: number
        }
        Insert: {
          expense_id: string
          group_id: string
          member_id: string
          paid_cents: number
        }
        Update: {
          expense_id?: string
          group_id?: string
          member_id?: string
          paid_cents?: number
        }
        Relationships: [
          {
            foreignKeyName: "expense_payers_expense_id_group_id_fkey"
            columns: ["expense_id", "group_id"]
            isOneToOne: false
            referencedRelation: "expenses"
            referencedColumns: ["id", "group_id"]
          },
          {
            foreignKeyName: "expense_payers_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "expense_payers_member_id_group_id_fkey"
            columns: ["member_id", "group_id"]
            isOneToOne: false
            referencedRelation: "members"
            referencedColumns: ["id", "group_id"]
          },
        ]
      }
      expense_revisions: {
        Row: {
          author_member_id: string | null
          changed_at: string
          expense_id: string
          group_id: string
          id: string
          revision: number
          snapshot: Json
        }
        Insert: {
          author_member_id?: string | null
          changed_at?: string
          expense_id: string
          group_id: string
          id?: string
          revision: number
          snapshot: Json
        }
        Update: {
          author_member_id?: string | null
          changed_at?: string
          expense_id?: string
          group_id?: string
          id?: string
          revision?: number
          snapshot?: Json
        }
        Relationships: [
          {
            foreignKeyName: "expense_revisions_author_member_id_group_id_fkey"
            columns: ["author_member_id", "group_id"]
            isOneToOne: false
            referencedRelation: "members"
            referencedColumns: ["id", "group_id"]
          },
          {
            foreignKeyName: "expense_revisions_expense_id_group_id_fkey"
            columns: ["expense_id", "group_id"]
            isOneToOne: false
            referencedRelation: "expenses"
            referencedColumns: ["id", "group_id"]
          },
          {
            foreignKeyName: "expense_revisions_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
        ]
      }
      expense_shares: {
        Row: {
          expense_id: string
          group_id: string
          member_id: string
          share_cents: number
          weight: number
        }
        Insert: {
          expense_id: string
          group_id: string
          member_id: string
          share_cents: number
          weight: number
        }
        Update: {
          expense_id?: string
          group_id?: string
          member_id?: string
          share_cents?: number
          weight?: number
        }
        Relationships: [
          {
            foreignKeyName: "expense_shares_expense_id_group_id_fkey"
            columns: ["expense_id", "group_id"]
            isOneToOne: false
            referencedRelation: "expenses"
            referencedColumns: ["id", "group_id"]
          },
          {
            foreignKeyName: "expense_shares_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "expense_shares_member_id_group_id_fkey"
            columns: ["member_id", "group_id"]
            isOneToOne: false
            referencedRelation: "members"
            referencedColumns: ["id", "group_id"]
          },
        ]
      }
      expenses: {
        Row: {
          amount_cents: number
          category: string | null
          created_at: string
          currency: string
          date: string
          deleted_at: string | null
          fx_rate_ppm: number
          group_amount_cents: number
          group_id: string
          id: string
          server_seq: number
          split_mode: string
          title: string
          trip_meta: Json | null
          type: string
          updated_at: string
        }
        Insert: {
          amount_cents: number
          category?: string | null
          created_at?: string
          currency: string
          date: string
          deleted_at?: string | null
          fx_rate_ppm: number
          group_amount_cents: number
          group_id: string
          id: string
          server_seq: number
          split_mode: string
          title: string
          trip_meta?: Json | null
          type: string
          updated_at: string
        }
        Update: {
          amount_cents?: number
          category?: string | null
          created_at?: string
          currency?: string
          date?: string
          deleted_at?: string | null
          fx_rate_ppm?: number
          group_amount_cents?: number
          group_id?: string
          id?: string
          server_seq?: number
          split_mode?: string
          title?: string
          trip_meta?: Json | null
          type?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "expenses_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
        ]
      }
      fuel_price_cache: {
        Row: {
          approximation: string | null
          fetched_at: string
          observed_at: string | null
          price_milli: number
          scope: string
          scope_key: string
          source: string
          stations: number
          type: string
        }
        Insert: {
          approximation?: string | null
          fetched_at?: string
          observed_at?: string | null
          price_milli: number
          scope: string
          scope_key: string
          source?: string
          stations: number
          type: string
        }
        Update: {
          approximation?: string | null
          fetched_at?: string
          observed_at?: string | null
          price_milli?: number
          scope?: string
          scope_key?: string
          source?: string
          stations?: number
          type?: string
        }
        Relationships: []
      }
      fx_rates: {
        Row: {
          base: string
          date: string
          fetched_at: string
          quote: string
          rate_ppm: number
          source_date: string
        }
        Insert: {
          base: string
          date: string
          fetched_at?: string
          quote: string
          rate_ppm: number
          source_date: string
        }
        Update: {
          base?: string
          date?: string
          fetched_at?: string
          quote?: string
          rate_ppm?: number
          source_date?: string
        }
        Relationships: []
      }
      group_invites: {
        Row: {
          created_at: string
          created_by: string
          expires_at: string
          group_id: string
          id: string
          revoked_at: string | null
          token_hash: string
        }
        Insert: {
          created_at?: string
          created_by: string
          expires_at: string
          group_id: string
          id?: string
          revoked_at?: string | null
          token_hash: string
        }
        Update: {
          created_at?: string
          created_by?: string
          expires_at?: string
          group_id?: string
          id?: string
          revoked_at?: string | null
          token_hash?: string
        }
        Relationships: [
          {
            foreignKeyName: "group_invites_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
        ]
      }
      group_memberships: {
        Row: {
          created_at: string
          group_id: string
          id: string
          member_id: string | null
          user_id: string
        }
        Insert: {
          created_at?: string
          group_id: string
          id?: string
          member_id?: string | null
          user_id: string
        }
        Update: {
          created_at?: string
          group_id?: string
          id?: string
          member_id?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "group_memberships_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "group_memberships_member_id_group_id_fkey"
            columns: ["member_id", "group_id"]
            isOneToOne: false
            referencedRelation: "members"
            referencedColumns: ["id", "group_id"]
          },
        ]
      }
      groups: {
        Row: {
          created_at: string
          created_by: string
          currency: string
          deleted_at: string | null
          id: string
          name: string
          server_seq: number
          updated_at: string
        }
        Insert: {
          created_at?: string
          created_by: string
          currency: string
          deleted_at?: string | null
          id: string
          name: string
          server_seq: number
          updated_at: string
        }
        Update: {
          created_at?: string
          created_by?: string
          currency?: string
          deleted_at?: string | null
          id?: string
          name?: string
          server_seq?: number
          updated_at?: string
        }
        Relationships: []
      }
      members: {
        Row: {
          created_at: string
          deleted_at: string | null
          group_id: string
          iban_hint: string | null
          id: string
          name: string
          paypal_me: string | null
          position: number
          server_seq: number
          updated_at: string
          user_id: string | null
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          group_id: string
          iban_hint?: string | null
          id: string
          name: string
          paypal_me?: string | null
          position: number
          server_seq: number
          updated_at: string
          user_id?: string | null
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          group_id?: string
          iban_hint?: string | null
          id?: string
          name?: string
          paypal_me?: string | null
          position?: number
          server_seq?: number
          updated_at?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "members_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
        ]
      }
      rate_limits: {
        Row: {
          key_hash: string
          tokens: number
          updated_at: string
        }
        Insert: {
          key_hash: string
          tokens: number
          updated_at?: string
        }
        Update: {
          key_hash?: string
          tokens?: number
          updated_at?: string
        }
        Relationships: []
      }
      ride_templates: {
        Row: {
          created_at: string
          default_driver_id: string | null
          default_passenger_ids: Json
          deleted_at: string | null
          distance_meters: number
          group_id: string
          id: string
          name: string
          round_trip: boolean
          server_seq: number
          tolls_cents: number
          updated_at: string
          vehicle_id: string
        }
        Insert: {
          created_at?: string
          default_driver_id?: string | null
          default_passenger_ids?: Json
          deleted_at?: string | null
          distance_meters: number
          group_id: string
          id: string
          name: string
          round_trip?: boolean
          server_seq: number
          tolls_cents?: number
          updated_at: string
          vehicle_id: string
        }
        Update: {
          created_at?: string
          default_driver_id?: string | null
          default_passenger_ids?: Json
          deleted_at?: string | null
          distance_meters?: number
          group_id?: string
          id?: string
          name?: string
          round_trip?: boolean
          server_seq?: number
          tolls_cents?: number
          updated_at?: string
          vehicle_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "ride_templates_default_driver_id_group_id_fkey"
            columns: ["default_driver_id", "group_id"]
            isOneToOne: false
            referencedRelation: "members"
            referencedColumns: ["id", "group_id"]
          },
          {
            foreignKeyName: "ride_templates_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ride_templates_vehicle_id_group_id_fkey"
            columns: ["vehicle_id", "group_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id", "group_id"]
          },
        ]
      }
      rides: {
        Row: {
          created_at: string
          date: string
          deleted_at: string | null
          distance_meters: number
          driver_counts: boolean
          driver_id: string
          group_id: string
          id: string
          passenger_ids: Json
          price_per_unit_milli: number
          round_trip: boolean
          server_seq: number
          settled_expense_id: string | null
          tolls_cents: number
          updated_at: string
          use_km_rate: boolean
          vehicle_id: string
        }
        Insert: {
          created_at?: string
          date: string
          deleted_at?: string | null
          distance_meters: number
          driver_counts?: boolean
          driver_id: string
          group_id: string
          id: string
          passenger_ids?: Json
          price_per_unit_milli: number
          round_trip?: boolean
          server_seq: number
          settled_expense_id?: string | null
          tolls_cents?: number
          updated_at: string
          use_km_rate?: boolean
          vehicle_id: string
        }
        Update: {
          created_at?: string
          date?: string
          deleted_at?: string | null
          distance_meters?: number
          driver_counts?: boolean
          driver_id?: string
          group_id?: string
          id?: string
          passenger_ids?: Json
          price_per_unit_milli?: number
          round_trip?: boolean
          server_seq?: number
          settled_expense_id?: string | null
          tolls_cents?: number
          updated_at?: string
          use_km_rate?: boolean
          vehicle_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "rides_driver_id_group_id_fkey"
            columns: ["driver_id", "group_id"]
            isOneToOne: false
            referencedRelation: "members"
            referencedColumns: ["id", "group_id"]
          },
          {
            foreignKeyName: "rides_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "rides_settled_expense_id_group_id_fkey"
            columns: ["settled_expense_id", "group_id"]
            isOneToOne: false
            referencedRelation: "expenses"
            referencedColumns: ["id", "group_id"]
          },
          {
            foreignKeyName: "rides_vehicle_id_group_id_fkey"
            columns: ["vehicle_id", "group_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id", "group_id"]
          },
        ]
      }
      settlements: {
        Row: {
          amount_cents: number
          created_at: string
          currency: string
          date: string
          deleted_at: string | null
          from_member: string
          group_id: string
          id: string
          method: string
          server_seq: number
          to_member: string
          updated_at: string
        }
        Insert: {
          amount_cents: number
          created_at?: string
          currency: string
          date: string
          deleted_at?: string | null
          from_member: string
          group_id: string
          id: string
          method: string
          server_seq: number
          to_member: string
          updated_at: string
        }
        Update: {
          amount_cents?: number
          created_at?: string
          currency?: string
          date?: string
          deleted_at?: string | null
          from_member?: string
          group_id?: string
          id?: string
          method?: string
          server_seq?: number
          to_member?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "settlements_from_member_group_id_fkey"
            columns: ["from_member", "group_id"]
            isOneToOne: false
            referencedRelation: "members"
            referencedColumns: ["id", "group_id"]
          },
          {
            foreignKeyName: "settlements_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "settlements_to_member_group_id_fkey"
            columns: ["to_member", "group_id"]
            isOneToOne: false
            referencedRelation: "members"
            referencedColumns: ["id", "group_id"]
          },
        ]
      }
      vehicles: {
        Row: {
          consumption_milli_per100km: number
          created_at: string
          deleted_at: string | null
          fuel_type: string
          group_id: string
          id: string
          km_rate_milli_per_km: number | null
          name: string
          server_seq: number
          updated_at: string
          wear_milli_per_km: number
        }
        Insert: {
          consumption_milli_per100km: number
          created_at?: string
          deleted_at?: string | null
          fuel_type: string
          group_id: string
          id: string
          km_rate_milli_per_km?: number | null
          name: string
          server_seq: number
          updated_at: string
          wear_milli_per_km?: number
        }
        Update: {
          consumption_milli_per100km?: number
          created_at?: string
          deleted_at?: string | null
          fuel_type?: string
          group_id?: string
          id?: string
          km_rate_milli_per_km?: number | null
          name?: string
          server_seq?: number
          updated_at?: string
          wear_milli_per_km?: number
        }
        Relationships: [
          {
            foreignKeyName: "vehicles_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      can_bootstrap_group: { Args: { gid: string }; Returns: boolean }
      cleanup_fuel_tables: { Args: never; Returns: undefined }
      cleanup_fx_rates: { Args: never; Returns: undefined }
      consume_rate_limit: {
        Args: { p_capacity: number; p_key: string; p_refill_per_sec: number }
        Returns: boolean
      }
      create_invite: { Args: { gid: string }; Returns: string }
      delete_my_data: { Args: never; Returns: Json }
      is_group_member: { Args: { gid: string }; Returns: boolean }
      join_group: {
        Args: { claim_member_id?: string; token: string }
        Returns: Json
      }
      revoke_invite: { Args: { invite_id: string }; Returns: undefined }
      upsert_expense: { Args: { payload: Json }; Returns: Json }
      warm_fuel_national: { Args: never; Returns: undefined }
      warm_fx_rates: { Args: never; Returns: undefined }
    }
    Enums: {
      [_ in never]: never
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
    Enums: {},
  },
} as const

