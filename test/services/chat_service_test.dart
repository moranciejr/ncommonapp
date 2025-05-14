import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ncommonapp/services/chat_service.dart';

@GenerateMocks([
  StreamChatClient,
  FirebaseAnalytics,
  SupabaseClient,
  Channel,
  User,
  PostgrestResponse,
])
void main() {
  late ChatService chatService;
  late MockStreamChatClient mockClient;
  late MockFirebaseAnalytics mockAnalytics;
  late MockSupabaseClient mockSupabase;
  late MockChannel mockChannel;
  late MockUser mockUser;
  late MockPostgrestResponse mockResponse;

  setUp(() {
    mockClient = MockStreamChatClient();
    mockAnalytics = MockFirebaseAnalytics();
    mockSupabase = MockSupabaseClient();
    mockChannel = MockChannel();
    mockUser = MockUser();
    mockResponse = MockPostgrestResponse();

    // Configure mock client
    when(mockClient.state).thenReturn(StreamChatState());
    when(mockClient.state.currentUser).thenReturn(mockUser);

    // Configure mock Supabase
    when(mockSupabase.auth).thenReturn(MockAuth());
    when(mockSupabase.auth.currentUser).thenReturn(mockUser);
    when(mockSupabase.functions.invoke(any, body: anyNamed('body')))
        .thenAnswer((_) async => mockResponse);
    when(mockResponse.data).thenReturn({'token': 'test_token'});

    chatService = ChatService(
      client: mockClient,
      analytics: mockAnalytics,
      supabase: mockSupabase,
    );
  });

  group('ChatService Tests', () {
    test('connectUser success', () async {
      // Arrange
      const userId = 'test_user';
      when(mockUser.id).thenReturn(userId);
      when(mockClient.connectUser(any, any)).thenAnswer((_) async => mockUser);

      // Act
      await chatService.connectUser();

      // Assert
      verify(mockSupabase.functions.invoke(
        'generate-stream-token',
        body: {'user_id': userId},
      )).called(1);
      verify(mockClient.connectUser(any, any)).called(1);
      verify(mockAnalytics.logEvent(
        name: 'chat_user_connected',
        parameters: {'user_id': userId},
      )).called(1);
    });

    test('connectUser failure - no user', () async {
      // Arrange
      when(mockSupabase.auth.currentUser).thenReturn(null);

      // Act & Assert
      expect(() => chatService.connectUser(), throwsException);
      verify(mockAnalytics.logEvent(
        name: 'chat_connection_error',
        parameters: {'error': 'Exception: No authenticated user found'},
      )).called(1);
    });

    test('connectUser failure - token error', () async {
      // Arrange
      const userId = 'test_user';
      when(mockUser.id).thenReturn(userId);
      when(mockSupabase.functions.invoke(any, body: anyNamed('body')))
          .thenThrow(Exception('Token error'));

      // Act & Assert
      expect(() => chatService.connectUser(), throwsException);
      verify(mockAnalytics.logEvent(
        name: 'chat_connection_error',
        parameters: {'error': 'Exception: Token error'},
      )).called(1);
    });

    test('getUserChannels success', () async {
      // Arrange
      final channels = [mockChannel];
      when(mockClient.queryChannels(
        filter: anyNamed('filter'),
        sort: anyNamed('sort'),
      )).thenAnswer((_) async => channels);

      // Act
      final result = await chatService.getUserChannels();

      // Assert
      verify(mockClient.queryChannels(
        filter: anyNamed('filter'),
        sort: anyNamed('sort'),
      )).called(1);
      expect(result, equals(channels));
    });

    test('getUserChannels failure', () async {
      // Arrange
      when(mockClient.queryChannels(
        filter: anyNamed('filter'),
        sort: anyNamed('sort'),
      )).thenThrow(Exception('Query failed'));

      // Act & Assert
      expect(() => chatService.getUserChannels(), throwsException);
      verify(mockAnalytics.logEvent(
        name: 'chat_query_error',
        parameters: {'error': 'Exception: Query failed'},
      )).called(1);
    });

    test('createChannel success', () async {
      // Arrange
      const channelId = 'test_channel';
      const channelName = 'Test Channel';
      final members = ['user1', 'user2'];

      when(mockClient.channel(any, id: anyNamed('id'), extraData: anyNamed('extraData')))
          .thenReturn(mockChannel);
      when(mockChannel.create()).thenAnswer((_) async => mockChannel);

      // Act
      final channel = await chatService.createChannel(
        channelId: channelId,
        name: channelName,
        members: members,
      );

      // Assert
      verify(mockClient.channel(
        'messaging',
        id: channelId,
        extraData: {
          'name': channelName,
          'members': members,
        },
      )).called(1);
      verify(mockChannel.create()).called(1);
      verify(mockAnalytics.logEvent(
        name: 'chat_channel_created',
        parameters: {'channel_id': channelId},
      )).called(1);
      expect(channel, equals(mockChannel));
    });

    test('createChannel failure', () async {
      // Arrange
      const channelId = 'test_channel';
      when(mockClient.channel(any, id: anyNamed('id'), extraData: anyNamed('extraData')))
          .thenReturn(mockChannel);
      when(mockChannel.create())
          .thenThrow(Exception('Channel creation failed'));

      // Act & Assert
      expect(() => chatService.createChannel(channelId: channelId), throwsException);
      verify(mockAnalytics.logEvent(
        name: 'chat_channel_error',
        parameters: {'error': 'Exception: Channel creation failed'},
      )).called(1);
    });
  });
}

class MockAuth extends Mock implements Auth {} 