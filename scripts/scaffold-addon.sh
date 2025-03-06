#!/bin/bash

# Check if all required arguments are provided
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <addon-name> <chart-repo> <chart-version> <namespace> <addon-type>"
    exit 1
fi

ADDON_NAME=$1
CHART_REPO=$2
CHART_VERSION=$3
NAMESPACE=$4
ADDON_TYPE=$5
OUTPUT_FILE="bootstrap/control-plane/addons/${ADDON_TYPE}/addons-${ADDON_NAME}-appset.yaml"

# Validate addon type
if [ "${ADDON_TYPE}" != "oss" ] && [ "${ADDON_TYPE}" != "aws" ] && [ "${ADDON_TYPE}" != "nsx" ]; then
    echo "Invalid addon type. Must be one of: oss, aws, nsx"
    exit 1
fi

# Create the ApplicationSet YAML
cat > "$OUTPUT_FILE" << EOF
---
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: addons-${ADDON_NAME}
spec:
  goTemplate: true
  syncPolicy:
    preserveResourcesOnDeletion: true
  generators:
    - merge:
        mergeKeys: [server]
        generators:
          - clusters:
              values:
                addonChart: ${ADDON_NAME}
                addonChartVersion: ${CHART_VERSION}
                addonChartRepositoryNamespace: ${NAMESPACE}
                addonChartRepository: ${CHART_REPO}
              selector:
                matchExpressions:
                  - key: akuity.io/argo-cd-cluster-name
                    operator: NotIn
                    values: [in-cluster]
                  - key: enable_${ADDON_NAME//-/_}
                    operator: In
                    values: ['true']
          - clusters:
              selector:
                matchLabels:
                  environment: staging
              values:
                addonChartVersion: ${CHART_VERSION}
          - clusters:
              selector:
                matchLabels:
                  environment: prod
              values:
                addonChartVersion: ${CHART_VERSION}
  template:
    metadata:
      name: addon-{{.name}}-{{.values.addonChart}}
    spec:
      project: default
      sources:
        - repoURL: '{{.metadata.annotations.addons_repo_url}}'
          targetRevision: '{{.metadata.annotations.addons_repo_revision}}'
          ref: values
        - chart: ${ADDON_NAME}
          repoURL: '{{values.addonChartRepository}}'
          targetRevision: '{{values.addonChartVersion}}'
          helm:
            releaseName: ${ADDON_NAME}
            ignoreMissingValueFiles: true
            valueFiles:
              - \$values/{{.metadata.annotations.addons_repo_basepath}}environments/default/addons/{{.values.addonChart}}/values.yaml
              - \$values/{{.metadata.annotations.addons_repo_basepath}}environments/{{.metadata.labels.environment}}/addons/{{.values.addonChart}}/values.yaml
              - \$values/{{.metadata.annotations.addons_repo_basepath}}environments/clusters/{{.name}}/addons/{{.values.addonChart}}/values.yaml
      destination:
        namespace: '{{.values.addonChartRepositoryNamespace}}'
        name: '{{.name}}'
      syncPolicy:
        automated: {}
        syncOptions:
          - CreateNamespace=true
          - ServerSideApply=true
EOF

echo "Created new addon ApplicationSet at: $OUTPUT_FILE"

# Create the directory structure for values
mkdir -p "environments/default/addons/${ADDON_NAME}"
touch "environments/default/addons/${ADDON_NAME}/values.yaml"

echo "Created values.yaml template at: environments/default/addons/${ADDON_NAME}/values.yaml"