import React from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';

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
                Fluttron is a Dart-native cross-platform container OS.
              </p>

              <p>
                It is inspired by Electron, but designed for Flutter teams that want native host capabilities and web rendering flexibility without leaving Dart.
              </p>

              <h2>What is Fluttron?</h2>

              <p>
                Fluttron combines:
              </p>

              <ul>
                <li><strong>Host:</strong> Flutter native app for lifecycle and service capabilities.</li>
                <li><strong>Renderer:</strong> Flutter Web app running in WebView.</li>
                <li><strong>Bridge:</strong> request/response IPC between Host and Renderer.</li>
              </ul>

              <h2>Key Features</h2>

              <ul>
                <li><strong>Web View System:</strong> Embed HTML/JS/CSS into Flutter Web with type-driven rendering.</li>
                <li><strong>Event Bridge:</strong> JS→Flutter custom event communication.</li>
                <li><strong>Custom Services:</strong> Extend Host with your own services.</li>
                <li><strong>CLI Pipeline:</strong> Create, build, and run projects with one command.</li>
              </ul>

              <h2>Current MVP Status</h2>

              <ul>
                <li>CLI pipeline (`create/build/run`) is available.</li>
                <li>Template frontend build pipeline is available (`pnpm` + `esbuild`).</li>
                <li>Core UI library with `FluttronHtmlView`, `FluttronEventBridge`, and `FluttronWebViewRegistry`.</li>
                <li>Host custom service extension support with template example.</li>
              </ul>

              <h2>Get Started</h2>

              <div className="margin-vert--xl">
                <Link
                  className="button button--primary button--lg"
                  to="/docs/getting-started/quick-start">
                  Quick Start
                </Link>
              </div>
            </div>
          </div>
        </div>
      </main>
    </Layout>
  );
}
