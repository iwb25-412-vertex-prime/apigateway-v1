"use client";

import { DashboardLayout } from "@/components/DashboardLayout";
import { ApiDocumentation } from "@/components/ApiDocumentation";

export default function DocsPage() {
  return (
    <DashboardLayout>
      <div className="p-6">
        <ApiDocumentation />
      </div>
    </DashboardLayout>
  );
}
