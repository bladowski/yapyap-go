import { Component, type ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
}

export default class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false };

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  render() {
    if (this.state.hasError) {
      return (
        this.props.fallback ?? (
          <div className="flex items-center justify-center h-full text-gray-500 p-8">
            <div className="text-center">
              <p className="text-lg font-semibold mb-2">Map unavailable</p>
              <p className="text-sm">
                {this.state.error?.message ?? 'WebGL not available in this browser.'}
              </p>
            </div>
          </div>
        )
      );
    }
    return this.props.children;
  }
}
