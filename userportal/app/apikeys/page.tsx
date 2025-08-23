'use client';

import { DashboardLayout } from '@/components/DashboardLayout';
import { ApiKeyManagement } from '@/components/ApiKeyManagement';

export default function ApiKeysPage() {
  return (
    <DashboardLayout>
      <div className="p-6">
        <ApiKeyManagement />
      </div>
    </DashboardLayout>
  );
}