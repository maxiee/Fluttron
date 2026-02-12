import React from 'react';
import ComponentCreator from '@docusaurus/ComponentCreator';

export default [
  {
    path: '/Fluttron/zh-CN/docs',
    component: ComponentCreator('/Fluttron/zh-CN/docs', 'f0c'),
    routes: [
      {
        path: '/Fluttron/zh-CN/docs',
        component: ComponentCreator('/Fluttron/zh-CN/docs', 'a40'),
        routes: [
          {
            path: '/Fluttron/zh-CN/docs',
            component: ComponentCreator('/Fluttron/zh-CN/docs', 'db0'),
            routes: [
              {
                path: '/Fluttron/zh-CN/docs/api/services',
                component: ComponentCreator('/Fluttron/zh-CN/docs/api/services', 'a92'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/Fluttron/zh-CN/docs/api/web-views',
                component: ComponentCreator('/Fluttron/zh-CN/docs/api/web-views', '718'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/Fluttron/zh-CN/docs/architecture/bridge-communication',
                component: ComponentCreator('/Fluttron/zh-CN/docs/architecture/bridge-communication', '186'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/Fluttron/zh-CN/docs/architecture/host-layer',
                component: ComponentCreator('/Fluttron/zh-CN/docs/architecture/host-layer', 'ecc'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/Fluttron/zh-CN/docs/architecture/overview',
                component: ComponentCreator('/Fluttron/zh-CN/docs/architecture/overview', '386'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/Fluttron/zh-CN/docs/architecture/renderer-layer',
                component: ComponentCreator('/Fluttron/zh-CN/docs/architecture/renderer-layer', 'e0b'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/Fluttron/zh-CN/docs/examples/hello-world',
                component: ComponentCreator('/Fluttron/zh-CN/docs/examples/hello-world', '9b8'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/Fluttron/zh-CN/docs/getting-started/installation',
                component: ComponentCreator('/Fluttron/zh-CN/docs/getting-started/installation', 'e4a'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/Fluttron/zh-CN/docs/getting-started/project-structure',
                component: ComponentCreator('/Fluttron/zh-CN/docs/getting-started/project-structure', '99a'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/Fluttron/zh-CN/docs/getting-started/quick-start',
                component: ComponentCreator('/Fluttron/zh-CN/docs/getting-started/quick-start', '4f0'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/Fluttron/zh-CN/docs/intro',
                component: ComponentCreator('/Fluttron/zh-CN/docs/intro', '3d9'),
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
    path: '/Fluttron/zh-CN/',
    component: ComponentCreator('/Fluttron/zh-CN/', 'f3e'),
    exact: true
  },
  {
    path: '*',
    component: ComponentCreator('*'),
  },
];
