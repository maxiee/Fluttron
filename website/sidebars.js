/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  tutorialSidebar: [
    'intro',
    {
      type: 'category',
      label: 'Getting Started',
      link: {type: 'doc', id: 'getting-started/installation'},
      items: [
        'getting-started/installation',
        'getting-started/quick-start',
        'getting-started/project-structure',
      ],
    },
    {
      type: 'category',
      label: 'Architecture',
      link: {type: 'doc', id: 'architecture/overview'},
      items: [
        'architecture/overview',
        'architecture/host-layer',
        'architecture/renderer-layer',
        'architecture/bridge-communication',
      ],
    },
    {
      type: 'category',
      label: 'API Reference',
      link: {type: 'doc', id: 'api/services'},
      items: [
        'api/services',
        'api/web-views',
        'api/web-packages',
      ],
    },
    {
      type: 'category',
      label: 'Examples',
      items: [
        'examples/hello-world',
        'examples/milkdown-editor',
      ],
    },
  ],
};

module.exports = sidebars;
