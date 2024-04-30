/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    serverComponentsExternalPackages: ['@nodemono2/lib2', 'ssh2'],
  },
  ...(process.env.BAZEL_BINDIR == null ? {
    // standalone output doesn't work for Bazel
    output: 'standalone',
  } : null),
};

export default nextConfig;
