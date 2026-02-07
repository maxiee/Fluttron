import React from 'react';
import clsx from 'clsx';
import styles from './HomepageFeatures.module.css';

const FeatureList = [
  {
    title: 'Full-Stack Dart',
    Svg: require('@site/static/img/dart-logo.svg').default,
    description: (
      <>
        Write both host services and UI in Dart. No need to switch between Node.js and frontend frameworks like in Electron.
      </>
    ),
  },
  {
    title: 'Service-Oriented Architecture',
    Svg: require('@site/static/img/service-arch.svg').default,
    description: (
      <>
        Expose native capabilities through ServiceRegistry. Easily extend with custom services for file system, database, system APIs.
      </>
    ),
  },
  {
    title: 'Frontend Asset Pipeline',
    Svg: require('@site/static/img/web-eco.svg').default,
    description: (
      <>
        Templates include a frontend workflow (`frontend/src -> web/ext`) powered by `pnpm` + `esbuild`, then synced into Host assets via CLI build.
      </>
    ),
  },
];

function Feature({Svg, title, description}) {
  return (
    <div className={clsx('col col--4', styles.featureCard)}>
      <div className="text--center">
        <Svg className={styles.featureIcon} role="img" />
      </div>
      <div className="text--center padding-horiz--md">
        <h3>{title}</h3>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures() {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
