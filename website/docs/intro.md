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

              <h2>Current MVP Status</h2>

              <ul>
                <li>CLI pipeline (`create/build/run`) is available.</li>
                <li>Template frontend build pipeline is available (`pnpm` + `esbuild`).</li>
                <li>v0025 blocker fixes are complete:
                  <ul>
                    <li>Host template includes `assets/www/ext/` declaration.</li>
                    <li>`js:clean` removes both JS/CSS artifacts and sourcemaps.</li>
                  </ul>
                </li>
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
