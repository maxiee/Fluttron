/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Fluttron',
  tagline: 'Dart-native Cross-Platform Container OS',
  favicon: 'img/favicon.ico',

  url: 'https://maxiee.github.io',
  baseUrl: '/Fluttron/',

  organizationName: 'maxiee',
  projectName: 'Fluttron',

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',

  i18n: {
    defaultLocale: 'en',
    locales: ['en', 'zh-CN'],
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
       ({
         docs: {
           sidebarPath: require.resolve('./sidebars.js'),
           editUrl: 'https://github.com/fluttron/fluttron/tree/main/website/',
         },
         theme: {
           customCss: require.resolve('./src/css/custom.css'),
         },
       }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      image: 'img/docusaurus-social-card.jpg',
      navbar: {
        title: 'Fluttron',
        logo: {
          alt: 'Fluttron Logo',
          src: 'img/logo.svg',
        },
        items: [
          {
            type: 'docSidebar',
            sidebarId: 'tutorialSidebar',
            position: 'left',
            label: 'Documentation',
          },
          {
            href: 'https://github.com/fluttron/fluttron',
            label: 'GitHub',
            position: 'right',
          },
        ],
      },
       footer: {
         style: 'dark',
         links: [
           {
             title: 'Docs',
             items: [
               {
                 label: 'Getting Started',
                 to: '/docs/intro',
               },
               {
                 label: 'Architecture',
                 to: '/docs/architecture/overview',
               },
               {
                 label: 'API Reference',
                 to: '/docs/api/services',
               },
             ],
           },
           {
             title: 'Community',
             items: [
               {
                 label: 'GitHub',
                 href: 'https://github.com/fluttron/fluttron',
               },
               {
                 label: 'Discord',
                 href: 'https://discord.gg/fluttron',
               },
               {
                 label: 'Twitter',
                 href: 'https://twitter.com/fluttron',
               },
             ],
           },
         ],
         copyright: `Copyright © ${new Date().getFullYear()} Fluttron. Built with Docusaurus.`,
       },
      prism: {
        additionalLanguages: ['dart', 'yaml'],
      },
    }),
};

module.exports = config;
