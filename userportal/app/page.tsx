"use client";

import Link from "next/link";
import { DashboardLayout } from "@/components/DashboardLayout";
import { DashboardHome } from "@/components/DashboardHome";
import { useAuth } from "@/hooks/useAuth";

export default function Home() {
  const { isAuthenticated } = useAuth();

  if (!isAuthenticated) {
    return (
      <div className="min-h-screen relative overflow-hidden">
        {/* Background Image */}
        <div
          className="absolute inset-0 bg-cover bg-center bg-no-repeat"
          style={{
            backgroundImage: "url(/background.webp)",
          }}
        ></div>

        {/* Background Overlay */}
        <div className="absolute inset-0 bg-gradient-to-br from-slate-50/80 via-white/70 to-orange-50/80"></div>

        <div className="relative z-10 flex items-center justify-center min-h-screen px-4">
          <div className="max-w-4xl mx-auto">
            {/* Glass Effect Container */}
            <div className="backdrop-blur-xl bg-white/20 border border-white/30 rounded-3xl p-12 md:p-16 shadow-2xl text-center">
              {/* Logo/Brand */}
              <div className="mb-12">
                <h1 className="text-6xl md:text-7xl font-bold text-slate-900 mb-6 tracking-tight">
                  Moderato
                </h1>
                <div className="w-24 h-1 bg-gradient-to-r from-orange-500 to-orange-600 mx-auto rounded-full"></div>
              </div>

              {/* Main Content */}
              <div className="mb-12">
                <h2 className="text-2xl md:text-3xl text-slate-800 mb-6 font-light">
                  Intelligent Content Moderation API
                </h2>
                <p className="text-lg text-slate-700 max-w-2xl mx-auto leading-relaxed">
                  Define and enforce custom content policies with our powerful
                  API. Secure, scalable, and developer-friendly.
                </p>
              </div>

              {/* CTA Buttons */}
              <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
                <Link
                  href="/auth"
                  className="bg-orange-600 text-white px-8 py-4 rounded-xl text-lg font-semibold hover:bg-orange-700 transition-all duration-300 transform hover:scale-105 shadow-lg hover:shadow-xl"
                >
                  Get Started
                </Link>
                <Link
                  href="/auth"
                  className="border-2 border-slate-400 text-slate-800 px-8 py-4 rounded-xl text-lg font-semibold hover:border-slate-500 hover:text-slate-900 hover:bg-white/30 transition-all duration-300"
                >
                  Sign In
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <DashboardLayout>
      <DashboardHome />
    </DashboardLayout>
  );
}
