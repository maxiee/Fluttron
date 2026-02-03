import React from 'react';
import ComponentCreator from '@docusaurus/ComponentCreator';

export default [
  {
    path: '/zh-CN/docs',
    component: ComponentCreator('/zh-CN/docs', '88c'),
    routes: [
      {
        path: '/zh-CN/docs',
        component: ComponentCreator('/zh-CN/docs', '4e5'),
        routes: [
          {
            path: '/zh-CN/docs',
            component: ComponentCreator('/zh-CN/docs', '560'),
            routes: [
              {
                path: '/zh-CN/docs/api/services',
                component: ComponentCreator('/zh-CN/docs/api/services', 'e83'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/zh-CN/docs/architecture/bridge-communication',
                component: ComponentCreator('/zh-CN/docs/architecture/bridge-communication', 'e09'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/zh-CN/docs/architecture/host-layer',
                component: ComponentCreator('/zh-CN/docs/architecture/host-layer', '023'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/zh-CN/docs/architecture/overview',
                component: ComponentCreator('/zh-CN/docs/architecture/overview', 'c14'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/zh-CN/docs/architecture/renderer-layer',
                component: ComponentCreator('/zh-CN/docs/architecture/renderer-layer', 'cd0'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/zh-CN/docs/examples/hello-world',
                component: ComponentCreator('/zh-CN/docs/examples/hello-world', '982'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/zh-CN/docs/getting-started/installation',
                component: ComponentCreator('/zh-CN/docs/getting-started/installation', '10b'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/zh-CN/docs/getting-started/project-structure',
                component: ComponentCreator('/zh-CN/docs/getting-started/project-structure', '1da'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/zh-CN/docs/getting-started/quick-start',
                component: ComponentCreator('/zh-CN/docs/getting-started/quick-start', '0a7'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/zh-CN/docs/intro',
                component: ComponentCreator('/zh-CN/docs/intro', '1c9'),
                exact: true,
                sidebar: "tutorialSidebar"
              }
            ]
          }
        ]
      }
    ]
  },
  {
    path: '/zh-CN/',
    component: ComponentCreator('/zh-CN/', '42a'),
    exact: true
  },
  {
    path: '*',
    component: ComponentCreator('*'),
  },
];
