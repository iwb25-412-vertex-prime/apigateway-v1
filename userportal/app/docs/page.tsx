"use client";

import { DashboardLayout, ApiDocumentation } from "@/components";

export default function DocsPage() {
  return (
    <DashboardLayout>
      <div className="p-6">
        <ApiDocumentation />
      </div>
    </DashboardLayout>
  );
}
