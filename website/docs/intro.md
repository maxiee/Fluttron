import React from 'react';
import clsx from 'clsx';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';

import styles from './index.module.css';

export default function Hello() {
  return (
    <Layout title="Hello" description="Hello">
      <main>
        <div className="container padding-top--lg padding-bottom--xl">
          <div className="row">
            <div className="col col--6 col--offset-3">
              <h1 className={styles.title}>Introduction to Fluttron</h1>

              <p>
                Welcome to Fluttron, the Dart-native cross-platform container OS.
              </p>

              <p>
                Fluttron is inspired by Electron but designed specifically for Dart developers. It provides a unified development experience where both the host layer and the renderer layer are written in Dart and Flutter.
              </p>

              <h2>What is Fluttron?</h2>

              <p>
                Fluttron is a cross-platform container OS that combines the stability of native host applications with the flexibility of web rendering. It enables Dart developers to build cross-platform applications using only Dart and Flutter technologies.
              </p>

              <h2>Key Concepts</h2>

              <ul>
                <li><strong>Host Layer:</strong> Built with Flutter Desktop, manages windows, lifecycle, and exposes native capabilities through ServiceRegistry.</li>
                <li><strong>Renderer Layer:</strong> Built with Flutter Web, runs in a controlled WebView container, handles UI rendering and business logic.</li>
                <li><strong>Bridge Communication:</strong> High-performance IPC mechanism between Host and Renderer using JavaScript Handlers.</li>
              </ul>

              <h2>Why Fluttron?</h2>

              <p>
                Electron dominates desktop development with Node.js and Chromium, but requires Dart developers to switch technology stacks. Fluttron eliminates this barrier, allowing you to work entirely in Dart across both the system layer and UI layer.
              </p>

              <div className="margin-vert--xl">
                <Link
                  className="button button--primary button--lg"
                  to="/docs/getting-started/installation">
                  Get Started
                </Link>
              </div>
            </div>
          </div>
        </div>
      </main>
    </Layout>
  );
}
