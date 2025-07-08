import { ApolloClient, InMemoryCache, createHttpLink, split } from '@apollo/client';
import { GraphQLWsLink } from '@apollo/client/link/subscriptions';
import { getMainDefinition } from '@apollo/client/utilities';
import { createClient } from 'graphql-ws';

// HTTP链接用于查询和变更
const httpLink = createHttpLink({
  uri: 'http://localhost:3000/graphql', // 替换为你的GraphQL服务器地址
});

// WebSocket链接用于subscription
const wsLink = new GraphQLWsLink(
  createClient({
    url: 'ws://localhost:3000/graphql', // 替换为你的WebSocket地址
    connectionParams: {
      headers: {
        'Access-Control-Allow-Origin': '*',
      },
    },
  })
);

// 分割链接：HTTP用于查询/变更，WebSocket用于subscription
const splitLink = split(
  ({ query }) => {
    const definition = getMainDefinition(query);
    return (
      definition.kind === 'OperationDefinition' &&
      definition.operation === 'subscription'
    );
  },
  wsLink,
  httpLink
);

// 创建Apollo客户端
export const client = new ApolloClient({
  link: splitLink,
  cache: new InMemoryCache(),
  defaultOptions: {
    watchQuery: {
      errorPolicy: 'all',
    },
    query: {
      errorPolicy: 'all',
    },
  },
}); 