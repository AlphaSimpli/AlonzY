CREATE OR REPLACE FUNCTION public.touch_conversation_from_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
	UPDATE public.conversations
	SET last_message = NEW.message,
			last_message_at = NEW.created_at,
			last_sender_id = NEW.sender_id
	WHERE id = NEW.conversation_id;
	RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS touch_conversation_on_message ON public.chat_messages;
CREATE TRIGGER touch_conversation_on_message
	AFTER INSERT ON public.chat_messages
	FOR EACH ROW EXECUTE FUNCTION public.touch_conversation_from_message();

NOTIFY pgrst, 'reload schema';
