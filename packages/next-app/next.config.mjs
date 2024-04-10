/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    serverComponentsExternalPackages: ['@nodemono2/lib2', 'ssh2'],
  },
  output: 'standalone',
};

export default nextConfig;
