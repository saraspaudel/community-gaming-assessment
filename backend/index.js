import express from 'express';
import graphiql from 'express-graphql';
const expressGraphQL = graphiql.graphqlHTTP;
import { GraphQLSchema, GraphQLObjectType, GraphQLString, GraphQLList, GraphQLInt, GraphQLNonNull } from 'graphql';
import { stakedTokens, rewardTokens, userData } from './utils/index.js';

// Create an express server and a GraphQL endpoint
var app = express();

const User = new GraphQLObjectType({
  name: 'user',
  description: 'This represents user entity',

  fields: () => ({
    address: {
      type: new GraphQLNonNull(GraphQLString),
    },
    rewards: {
      type: new GraphQLNonNull(GraphQLInt),
    },
    stakedToken: {
      type: new GraphQLNonNull(GraphQLInt),
    }
  }),
});

const RootQueryType = new GraphQLObjectType({
  name: 'Query',
  description: 'Root Query',
  fields: () => ({
    stakedTokens: {
      type: GraphQLInt,
      args: {
        address: { type: GraphQLString },
      },
      resolve: async (parent, args) => {
        return await stakedTokens(args.address);
      },
    },
    stakingRewards: {
      type: GraphQLInt,
      args: {
        address: { type: GraphQLString },
      },
      resolve: async (parent, args) => {
        return await rewardTokens(args.address);
      },
    },
    userData: {
      type: new GraphQLList(User),
      resolve: async () => {
        return await userData();
      },
    },
  }),
});
const schema = new GraphQLSchema({
  query: RootQueryType,
});
app.use(
  '/graphql',
  expressGraphQL({
    schema: schema,
    graphiql: true,
  })
);
app.listen(4000, () => console.log('Express GraphQL Server Now Running On localhost:4000/graphql'));
